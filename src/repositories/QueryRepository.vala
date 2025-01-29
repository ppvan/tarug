namespace Tarug {
    public class QueryRepository : Object {
        const string KEY = "queries";

        const string select_sql = """
        SELECT id, sql FROM "queries"
        ORDER BY create_at DESC;
        """;

        const string insert_sql = """
        INSERT INTO "queries" (sql) VALUES (?);
        """;

        const string update_sql = """
        UPDATE "queries"
        SET sql = ?
        WHERE id = ?;
        """;

        const string delete_sql = """
        DELETE FROM "queries"
        WHERE id = ?;
        """;

        const string delete_all_sql = """
        DELETE FROM "queries";
        """;

        private Sqlite.Statement select_stmt;
        private Sqlite.Statement insert_stmt;
        private Sqlite.Statement update_stmt;
        private Sqlite.Statement delete_stmt;
        private Sqlite.Statement delete_all_stmt;

        private StorageService db;
        private List<Query> _data;

        public QueryRepository(){
            base();

            this.db = autowire<StorageService> ();
            select_stmt = db.prepare(select_sql);
            insert_stmt = db.prepare(insert_sql);
            update_stmt = db.prepare(update_sql);
            delete_stmt = db.prepare(delete_sql);
            delete_all_stmt = db.prepare(delete_all_sql);
        }

        public List<Query> get_queries (){
            // debug ("Get query");

            return(this.find_all());
        }

        public void append_query (Query query){
            _data.append(query);

            insert_stmt.reset();
            insert_stmt.bind_text(1, query.sql);
            if (insert_stmt.step() != Sqlite.DONE) {
                debug("Error: %s", db.err_message());
            }
        }

        public void update_query (Query query){
            update_stmt.reset();
            update_stmt.bind_text(1, query.sql);
            update_stmt.bind_int64(2, query.id);
            if (update_stmt.step() != Sqlite.DONE) {
                debug("Error: %s", db.err_message());
            }
        }

        public void remove_query (Query query){
            _data.remove(query);
            delete_stmt.reset();
            delete_stmt.bind_int64(1, query.id);
            if (delete_stmt.step() != Sqlite.DONE) {
                debug("Error: %s", db.err_message());
            }
        }

        public List<Query> find_all (){
            select_stmt.reset();
            int cols = select_stmt.column_count();
            var list = new List<Query> ();

            while (select_stmt.step() == Sqlite.ROW) {
                Query query = new Query("");
                for (int i = 0; i < cols; i++) {
                    string col_name = select_stmt.column_name(i) ?? "<none>";
                    switch (col_name) {
                        case "id":
                            query.id = select_stmt.column_int64(i);
                            break;

                        case "sql":
                            query.sql = select_stmt.column_text(i);
                            break;

                        default:
                            debug("Unexpect column: %s\n", col_name);
                            break;
                    }
                }

                // debug ("id = %lli, sql = %s", query.id, query.sql);
                list.append(query);
            }

            return(list);
        }

        public void append_all (List<Query> items){
            items.foreach((item) => append_query(item));
        }

        public void clear (){
            delete_all_stmt.reset();
            if (delete_all_stmt.step() != Sqlite.DONE) {
                debug("Error: %s", db.err_message());
            }
        }
    }
}
