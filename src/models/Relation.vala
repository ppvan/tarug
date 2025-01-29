using Postgres;

namespace Tarug {
    public delegate Relation.Row TransFormsFunc (Relation.Row row);

/**
 * Relation class represent database "table".
 *
 * Not to confuse with Table class hold table info, this can hold any data return from database.
 */
    public class Relation : Object {
        public int rows { get; private set; }
        public int cols { get; private set; }
        /** Time of query created this relation in us */
        public int64 fetch_time { get; construct; }

        public string row_affected { get; private set; default = ""; }

        private Vec<Row> data;
        private Vec<string> headers;
        private Vec<Type> cols_type;

        public Relation(owned Result res){
            Object(fetch_time: 0);
            load_data((owned) res);
        }

        public Relation.with_fetch_time(owned Result res, int64 fetch_time){
            Object(fetch_time: fetch_time);
            load_data((owned) res);
        }

        public Relation.raw(Vec<string> headers, Vec<Row> data){
            Object(fetch_time: 0);
            this.rows = data.length;
            this.cols = headers.length;
            this.headers = headers;
            this.data = data;
        }

        public Type get_column_type (int index){
            return(this.cols_type[index]);
        }

        private void load_data (owned Result result){
            assert_nonnull(result);

            rows = result.get_n_tuples();
            cols = result.get_n_fields();
            row_affected = result.get_cmd_tuples();

            this.headers = new Vec<string>.with_capacity (cols);

            this.cols_type = new Vec<Type>.with_capacity (cols);

            for (int i = 0; i < cols; i++) {
                // Oid, should have enum for value type in VAPI but no.
                switch ((uint) result.get_field_type(i)) {
                    case 20, 21, 23:
                        // int
                        this.cols_type.append(Type.INT64);
                        break;

                    case 16:
                        // bool
                        this.cols_type.append(Type.BOOLEAN);
                        break;

                    case 700, 701:
                        // real
                        this.cols_type.append(Type.DOUBLE);
                        break;

                    case 25, 1043, 18, 19, 1700:
                        // string
                        this.cols_type.append(Type.STRING);
                        break;

                    case 1114:
                        // timestamp
                        this.cols_type.append(Type.STRING);
                        break;

                    case 1082:
                        // date
                        this.cols_type.append(Type.STRING);
                        break;

                    default:
                        this.cols_type.append(Type.STRING);
                        break;
                        // assert_not_reached ();
                }

                headers.append(result.get_field_name(i));
            }

            this.data = new Vec<Row>.with_capacity (rows);

            for (int i = 0; i < rows; i++) {
                var row = new Row(this.headers);
                for (int j = 0; j < cols; j++) {
                    row.add_field(result.get_value(i, j));
                }
                data.append(row);
            }
        }

        public Relation.Iterator iterator (){
            return(new Iterator(this));
        }

        public string get_header (int index){
            return(headers[index]);
        }

        public string to_string (){
            return(@"Table ($rows x $cols)");
        }

        public List<Row> steal (){
            return(this.data.as_list());
        }

        public Relation.Row[] as_array (){
            return this.data.as_array();
        }

        public string name { get; set; }

        public new Row @get (int index){
            return(data[index]);
        }

        public class Iterator {
            private Relation relation;
            private int index;

            public Iterator(Relation relation){
                this.relation = relation;
                this.index = 0;
            }

            public Relation.Row ? next_value(){
                if (index == relation.rows) {
                    return(null);
                }

                return(relation[index++]);
            }
        }

        /**
         * Helper class for ease of use with Relation.
         */
        public class Row : Object {
            private Vec<string> data;
            private unowned Vec<string> headers;

            public int size {
                get {
                    return(data.length);
                }
            }

            internal Row(Vec<string> headers){
                this.data = new Vec<string>.with_capacity (headers.length);

                this.headers = headers;
            }

            public void add_field (string item){
                data.append(item);
            }

            public new string ? @get (int index){
                return(data[index]);
            }

            public string ? get_by_header (string header){
                var index = -1;
                var cur = 0;
                foreach (var item in this.headers) {
                    if (item == header) {
                        index = cur;
                    }
                    cur++;
                }

                return(data[index]);
            }

            public string to_string (){
                var builder = new StringBuilder("");
                foreach (var item in this.data) {
                    builder.append_printf("%s\t\t", item);
                }

                return(builder.free_and_steal());
            }
        }
    }
}
