namespace Tarug {
    public class ConnectionRepository : Object {
        const string table_name = "connections";

        const string insert_sql = """
        INSERT INTO connections(name, host, port, user, password, database, use_ssl, options, cert_path) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;
        const string select_sql = """
        SELECT id, name, host, port, user, password, database, use_ssl, options, cert_path FROM connections;
        """;
        const string update_sql = """
        UPDATE connections
        SET name = ?, host = ?, port = ?, user = ?, password = ?, database = ?, use_ssl = ?, options = ?, cert_path = ?
        WHERE id = ?;
        """;
        const string delete_sql = """
        DELETE FROM connections
        WHERE id = ?;
        """;

        private Sqlite.Statement insert_stmt;
        private Sqlite.Statement select_stmt;
        private Sqlite.Statement update_stmt;
        private Sqlite.Statement delete_stmt;

        private StorageService db;



        public ConnectionRepository(){
            base();
            this.db = autowire<StorageService> ();
            this.insert_stmt = this.db.prepare(insert_sql);
            this.select_stmt = this.db.prepare(select_sql);
            this.update_stmt = this.db.prepare(update_sql);
            this.delete_stmt = this.db.prepare(delete_sql);
            find_all();
        }

        public Connection append_connection (Connection connection){
            this.insert_stmt.reset();
            insert_stmt.bind_text(1, connection.name);
            insert_stmt.bind_text(2, connection.host);
            insert_stmt.bind_text(3, connection.port);
            insert_stmt.bind_text(4, connection.user);
            insert_stmt.bind_text(5, connection.password);
            insert_stmt.bind_text(6, connection.database);
            insert_stmt.bind_int(7, connection.use_ssl ? 1 : 0);
            insert_stmt.bind_text(8, connection.options);
            insert_stmt.bind_text(9, connection.cert_path);

            if (insert_stmt.step() != Sqlite.DONE) {
                debug("Error: %s\n", db.err_message());
            }

            connection.id = db.last_insert_rowid();


            return(connection);
        }

        public void update_connection (Connection connection){
            // debug ("Update id = %lli, name = %s", connection.id, connection.name);
            this.update_stmt.reset();
            update_stmt.bind_text(1, connection.name);
            update_stmt.bind_text(2, connection.host);
            update_stmt.bind_text(3, connection.port);
            update_stmt.bind_text(4, connection.user);
            update_stmt.bind_text(5, connection.password);
            update_stmt.bind_text(6, connection.database);
            update_stmt.bind_int(7, connection.use_ssl ? 1 : 0);
            update_stmt.bind_text(8, connection.options);
            update_stmt.bind_text(9, connection.cert_path);
            update_stmt.bind_int64(10, connection.id);

            int code = update_stmt.step();
            if (code != Sqlite.DONE) {
                debug("Error: %s\n", db.err_message());
            }
        }

        public void remove_connection (Connection connection){
            this.delete_stmt.reset();
            delete_stmt.bind_int64(1, connection.id);

            if (delete_stmt.step() != Sqlite.DONE) {
                debug("Error: %s\n", db.err_message());
            }
        }

        public void append_all (List<Connection> items){
            items.foreach((item) => append_connection(item));
        }

        public void save (List<Connection> connections){
            var exist_connections = find_all();
            var exist_ids = new List<uint32> ();
            var ids = new List<uint32> ();
            exist_connections.foreach(item => exist_ids.append((uint32) item.id));
            connections.foreach(item => ids.append((uint32) item.id));


            foreach (var connection in connections) {
                if (connection.id == 0) {
                    append_connection(connection);
                } else {
                    if (exist_ids.index((uint32) connection.id) >= 0) {
                        // debug ("Update: %lli %s", connection.id, connection.name);
                        update_connection(connection);
                    }
                }
            }

            foreach (var connection in exist_connections) {
                if (ids.index((uint32) connection.id) < 0) {
                    remove_connection(connection);
                }
            }
        }

        public List<Connection> find_all (){
            select_stmt.reset();
            int cols = select_stmt.column_count();
            var list = new List<Connection> ();

            while (select_stmt.step() == Sqlite.ROW) {
                Connection conn = new Connection();
                for (int i = 0; i < cols; i++) {
                    string col_name = select_stmt.column_name(i) ?? "<none>";
                    switch (col_name) {
                        case "id":
                            conn.id = select_stmt.column_int64(i);
                            break;

                        case "name":
                            conn.name = select_stmt.column_text(i);
                            break;

                        case "host":
                            conn.host = select_stmt.column_text(i);
                            break;

                        case "port":
                            conn.port = select_stmt.column_text(i);
                            break;

                        case "user":
                            conn.user = select_stmt.column_text(i);
                            break;

                        case "password":
                            conn.password = select_stmt.column_text(i);
                            break;

                        case "database":
                            conn.database = select_stmt.column_text(i);
                            break;

                        case "use_ssl":
                            conn.use_ssl = select_stmt.column_int(i) != 0 ? true : false;
                            break;

                        case "options":
                            conn.options = select_stmt.column_text(i);
                            break;

                        case "cert_path":
                            conn.cert_path = select_stmt.column_text(i);
                            break;

                        default:
                            debug("Unexpect column: %s\n", col_name);
                            break;
                    }
                }

                list.append(conn);
            }

            return(list);
        }
    }
}
