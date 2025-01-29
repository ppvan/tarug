using Sqlite;

namespace Tarug {
    public class StorageService : Object {
        private string database_path;
        private Database connection;
        private string errmsg = "";

        public StorageService(string database_path){
            Object();
            this.database_path = database_path;
            int err = Database.open_v2(this.database_path, out this.connection);
            if (err != Sqlite.OK) {
                stderr.printf("Can't open database: %d: %s\n", connection.errcode(), connection.errmsg());
                Process.exit(1);
            }
        }

        public Relation exec (string sql, out string errmsg = null){
            var rows = new Vec<Relation.Row>();
            Vec<string> headers = new Vec<string>();


            this.connection.exec(sql, (n, values, colnames) => {
                if (headers.length == 0) {
                    headers = new Vec<string>.with_capacity(n);
                    for (int i = 0; i < n; i++) {
                        headers.append(colnames[i]);
                    }
                }

                var row = new Relation.Row(headers);
                for (int i = 0; i < n; i++) {
                    row.add_field(values[i]);
                }

                rows.append(row);
                return(0);
            }, out errmsg);

            return(new Relation.raw(headers, rows));
        }

        public int64 last_insert_rowid (){
            return(connection.last_insert_rowid());
        }

        public Statement ? prepare (string sql){
            Statement stmt;
            int err = connection.prepare_v2(sql, sql.length, out stmt, out errmsg);
            if (err != Sqlite.OK) {
                printerr(errmsg);
                return(null);
            }

            return(stmt);
        }

        public string err_message (){
            return(this.connection.errmsg());
        }
    }
}
