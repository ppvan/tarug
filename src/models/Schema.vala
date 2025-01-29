namespace Tarug {
/**
 * Carying schema info like tables and views.
 */
    public class Schema : Object {
        public string name { get; private set; }

        public Schema(string name){
            Object();
            this.name = name;
        }
    }

/** Base type for hold info about Table */
    public abstract class BaseType : Object {
        public string name { get; set; default = ""; }
        public string schemaname { get; set; default = ""; }
        public string table { get; set; default = ""; }

        public string to_string (){
            return(@"$schemaname.$name");
        }
    }

/** Table Index info */
    public class Index : BaseType {
        public bool unique { get; set; default = false; }
        public string index_type { get; set; default = "BTREE"; }
        public string[] columns { get; set; default = new string[] { "" }; }
        public string size { get; set; default = "0 kB"; }

        private string _indexdef;
        public string indexdef {
            get {
                return(_indexdef);
            }
            set {
                this._indexdef = value ?? "";
                this.extract_info();
            }
        }

        private void extract_info (){
            // unique = indexdef.contains ("UNIQUE");

            ////  Match the index type and column from indexdef, group 1 is type, group 2 is the column list.
            // var regex = /USING (btree|hash|gist|spgist|gin|brin|[\w]+) \(([a-zA-Z1-9+\-*\/_, ()]+)\)/;
            // MatchInfo match_info;
            // if (regex.match (indexdef, 0, out match_info)) {
            // index_type = IndexType.from_string (match_info.fetch (1));
            // columns = match_info.fetch (2);
            // } else {
            // warning ("Regex not match: %s", indexdef);
            // assert_not_reached ();
            // }
        }
    }

/** Table Column info */
    public class Column : BaseType {
        public string column_type { get; set; default = ""; }
        public bool nullable { get; set; default = false; }
        public string default_val { get; set; default = ""; }

        public bool is_primarykey { get; set; default = false; }
        public bool is_foreignkey { get; set; default = false; }

        public Column(){}
    }


    public class PrimaryKey : Object {
        public string table { get; set; default = ""; }
        public string name { get; set; default = ""; }
        public string[] columns { get; set; }

        public PrimaryKey(){}
    }
/** Table foreign key info */
    public class ForeignKey : Object {
        public string name { get; set; default = ""; }
        public string table { get; set; default = ""; }
        public string[] columns { get; set; }
        public string fk_table { get; set; default = ""; }
        public string[] fk_columns { get; set; }
    }
}
