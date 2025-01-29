namespace Tarug {
    public abstract class BaseTable : Object {
        public Schema schema { get; construct; }
        public string name { get; set; }
        public int64 row_count { get; set; default = 0; }
    }


/** Table object in database, hold meta-data about the table */
    public sealed class Table : BaseTable {
        public Vec<Column> columns { get; owned set; default = new Vec<Column> (); }
        public Vec<Index> indexes { get; owned set; default = new Vec<Index> (); }
        public Vec<ForeignKey> foreign_keys { get; owned set; default = new Vec<ForeignKey> (); }
        public Vec<PrimaryKey> primaty_keys { get; owned set; default = new Vec<PrimaryKey> (); }

        public Table(Schema schema){
            Object(schema: schema);
        }
    }

    public sealed class View : BaseTable {
        public Vec<Column> columns { get; owned set; default = new Vec<Column> (); }
        public string defs { get; set; default = ""; }

        public View(Schema schema){
            Object(schema: schema);
        }
    }
}
