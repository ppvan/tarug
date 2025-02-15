using Postgres;

namespace Tarug {
/** Main entry poit of application, exec query and return result.
 *
 * Do any thing relate to database, wrapper of libpq
 */
    public class SQLService : Object {
        public int query_limit { get; set; default = 100; }
        public int query_timeout { get; set; }

        private Settings settings;

        public SQLService(){
            Object();
            this.settings = autowire<Settings> ();

            settings.bind("query-limit", this, "query-limit", SettingsBindFlags.GET);
            settings.bind("query-timeout", this, "query-timeout", SettingsBindFlags.GET);
        }

        /** Select info from a table. */
        public async Relation select (BaseTable table, int page, int size = query_limit) throws TarugError {
            string schema_name = active_db.escape_identifier(table.schema.name);
            string escape_tbname = active_db.escape_identifier(table.name);
            int offset = page * size;
            int limit = size;

            string stmt = @"SELECT * FROM $schema_name.$escape_tbname LIMIT $limit OFFSET $offset";
            var query = new Query(stmt);
            return yield exec_query (query);
        }

        public async Relation select_where (BaseTable table, string where_clause, int page, int size = query_limit) throws TarugError {
            string schema_name = active_db.escape_identifier(table.schema.name);
            string escape_tbname = active_db.escape_identifier(table.name);
            int offset = page * size;
            int limit = size;

            // TODO make a better query builder
            var query_builder = new StringBuilder("SELECT * FROM");
            query_builder.append(@" $schema_name.$escape_tbname ");
            if (where_clause.strip() != "") {
                query_builder.append(@" WHERE $where_clause ");
            }
            query_builder.append(@" LIMIT $limit OFFSET $offset ");

            string stmt = query_builder.free_and_steal();
            var query = new Query(stmt);
            return yield exec_query (query);
        }

        /**
         * Make a async Postgres connection.
        */
        public async void connect_db (Connection conn) throws TarugError {
            var db_url = build_connection_string(conn);
            debug("Connecting to %s", db_url);
            start_connect (db_url);

            /*
             * Begin the polling loop to keep checking the connection is good
               Reference: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PQCONNECTSTARTPARAMS
               Setup: last_poll is WRITE
               Switch:
                    Case: WRITE -> wait until the socket ready to write.
                                   Refresh poll status and socket.
                                   Go to yield point
                    Case: READ  -> wait until the socket ready to write.
                                   Refresh poll and socket
                                   Go to yeild point
                    Case Failed: throw error
                    Case Sucess: Break the loop (success).
             */
            var last_poll = Postgres.PollingStatus.WRITING;
            var fd = active_db.get_socket ();
            SourceFunc go_to_yield = connect_db.callback;
            while (true) {
                if (last_poll == Postgres.PollingStatus.WRITING) {
                    var channel = new IOChannel.unix_new(fd);
                    channel.add_watch(IOCondition.OUT, (source, condition) => {
                        last_poll = active_db.connect_poll ();
                        fd = active_db.get_socket ();
                        go_to_yield();

                        return false;
                    });
                } else if (last_poll == Postgres.PollingStatus.READING) {
                    var channel = new IOChannel.unix_new(fd);
                    channel.add_watch(IOCondition.IN, (source, condition) => {
                        last_poll = active_db.connect_poll ();
                        fd = active_db.get_socket ();
                        go_to_yield();

                        return false;
                    });
                } else if (last_poll == Postgres.PollingStatus.FAILED) {
                    var err_msg = active_db.get_error_message();
                    throw new TarugError.CONNECTION_ERROR(err_msg);
                } else {
                    active_db = (owned)active_db;
                    active_chanel = new IOChannel.unix_new (active_db.get_socket ());
                    active_chanel.add_watch (IOCondition.IN | IOCondition.HUP, channel_signal_handler);
                    break;
                }
                yield; // give up cpu control
            }
        }

        private void start_connect(string db_url) throws TarugError {
            active_db = Postgres.connect_start (db_url);
            var status = active_db.get_status ();
            if (status == Postgres.ConnectionStatus.BAD) {
                var err_msg = active_db.get_error_message();
                throw new TarugError.CONNECTION_ERROR(err_msg);
            }
        }

        private string build_connection_string(Connection conn) {
            var connection_timeout = settings.get_int("connection-timeout");
            var query_timeout = settings.get_int("query-timeout");
            string db_url = conn.connection_string(connection_timeout, query_timeout);

            return db_url;
        }

        public async Relation exec_query (Query query) throws TarugError {
            var result = yield exec_query_epoll (query.sql);
            check_query_status(result);
            return new Relation((owned) result);
        }

        public Relation make_empty_relation (){
            var res = active_db.make_empty_result(ExecStatus.TUPLES_OK);
            return new Relation((owned) res);
        }

        public async Relation exec_query_params (Query query) throws TarugError {
            var result = yield exec_query_params_internal (query.sql, query.params);
            // check query status
            check_query_status(result);

            var table = new Relation((owned) result);

            return table;
        }

        private void check_query_status (Result result) throws TarugError {
            var status = result.get_status();

            switch (status) {
                case ExecStatus.TUPLES_OK, ExecStatus.COMMAND_OK, ExecStatus.COPY_OUT:
                    break;

                case ExecStatus.FATAL_ERROR:
                    var err_msg = result.get_error_message();
                    debug("Fatal error: %s", err_msg);
                    throw new TarugError.QUERY_FAIL(err_msg.dup());

                case ExecStatus.EMPTY_QUERY:
                    debug("Empty query");
                    throw new TarugError.QUERY_FAIL("Empty query");

                default:
                    warning("Programming error: %s not handled", status.to_string());
                    break;
            }
        }

        private async Result exec_query_epoll (string query){
            debug("Exec: %s", query);
            result_handler = exec_query_epoll.callback;
            int status = active_db.send_query (query);
            if (status != 1) {
                debug("%s", active_db.get_error_message ());
            }
            yield;
            result_handler = null;

            return (owned)active_result;
        }

        private async Result exec_query_params_internal (string query, Vec<string> params) throws TarugError {
            debug("Exec Param: %s", query);
            result_handler = exec_query_params_internal.callback;
            int status = active_db.send_query_params (query, (int) params.length, null, params.as_array(), null, null, 0);
            if (status != 1) {
                debug("%s", active_db.get_error_message ());
            }
            
            yield;
            result_handler = null;
            return (owned)active_result;
        }

        private bool channel_signal_handler(IOChannel source, IOCondition condition) {
            if (condition == IOCondition.HUP) {
                return false;
            }
            int status_code = active_db.consume_input();

            if (status_code == 1) {
                if (active_db.is_busy () == 0) {
                    active_result = active_db.get_result();
                    while(active_db.get_result() != null) {
                        //  TODO: handle muplite result.
                    }
                    result_handler();
                }
            }
            return true;
        }


        private Result active_result;
        private Database active_db;
        private IOChannel active_chanel;
        private SourceFunc? result_handler;
    }
}
