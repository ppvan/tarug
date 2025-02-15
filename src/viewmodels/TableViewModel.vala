namespace Tarug {
    public class TableViewModel : BaseViewModel {
        public Schema schema { get; set; }
        public ObservableList<Table> tables { get; set; default = new ObservableList<Table> (); }
        public Table ? selected_table { get; set; }


        public SQLService sql_service { get; private set; }

        // public signal void table_changed (Table table);

        public TableViewModel(SQLService sql_service){
            base();
            this.sql_service = sql_service;
            this.notify["selected-table"].connect(() => {
                EventBus.instance().selected_table_changed(selected_table);
            });

            EventBus.instance().schema_changed.connect((schema) => {
                tables.clear();
                load_tables.begin(schema);
            });
        }

        public void select_table (Table ? table){
            if (table == null) {
                return;
            }
            debug("selecting table %s", table.name);
            selected_table = table;
        }

        public void select_index (int index){
            if (tables[index] == null) {
                return;
            }
            debug("selecting table %s", tables[index].name);
            selected_table = tables[index];
        }

        private async void load_tables (Schema schema) throws TarugError {
            debug("loading tables in %s", schema.name);
            var query = new Query.with_params(TABLE_LIST, { schema.name });
            var relation = yield sql_service.exec_query_params (query);

            var table_vec = new Vec<Table>();

            foreach (var item in relation) {
                var table = new Table(schema);
                table.name = item[0];
                table.row_count = int64.parse(item[1], 10);

                table_vec.append(table);
            }

            debug("%d tables loaded", table_vec.length);

            var columns_query = new Query.with_params(COLUMN_SQL, { schema.name });
            var columns_relation = yield sql_service.exec_query_params (columns_query);

            foreach (var item in columns_relation) {
                var col = new Column();
                col.table = item[0];
                col.name = item[1];
                col.column_type = item[2];
                col.nullable = item[3] == "t" ? true : false;
                col.default_val = item[4];

                int index = table_vec.find((table) => {
                    return(table.name == col.table);
                });

                if (index == -1) {
                    var new_table = new Table(schema);
                    new_table.name = col.table;
                    new_table.columns.append(col);
                    table_vec.append(new_table);
                    continue;
                }

                table_vec[index].columns.append(col);

                debug("table-name: %s, columns: %d, col-name: %s", table_vec[index].name, table_vec[index].columns.length, col.name);
            }

            var indexes_query = new Query.with_params(INDEX_SQL, { schema.name });
            var indexes_relation = yield sql_service.exec_query_params (indexes_query);

            foreach (var item in indexes_relation) {
                var index = new Index();
                index.name = item[0];
                index.table = item[1];
                index.columns = parse_array_result(item[2]);
                index.indexdef = item[2];
                index.size = item[3];
                index.unique = item[4] == "t" ? true : false;
                index.index_type = item[5];

                int idx = table_vec.find((table) => {
                    return(table.name == index.table);
                });

                if (idx == -1) {
                    var new_table = new Table(schema);
                    new_table.name = index.table;
                    new_table.indexes.append(index);
                    table_vec.append(new_table);
                    continue;
                }

                table_vec[idx].indexes.append(index);
            }

            var primary_query = new Query.with_params(PK_SQL, { schema.name });
            var primary_relation = yield sql_service.exec_query_params (primary_query);

            foreach (var item in primary_relation) {
                var pk = new PrimaryKey();
                pk.name = item[0];
                pk.table = item[1];
                pk.columns = parse_array_result(item[2]);



                int idx = table_vec.find((table) => {
                    return(table.name == pk.table);
                });

                if (idx == -1) {
                    var new_table = new Table(schema);
                    new_table.name = pk.table;
                    new_table.primaty_keys.append(pk);
                    table_vec.append(new_table);
                    continue;
                }

                table_vec[idx].primaty_keys.append(pk);
            }

            var foreignkey_query = new Query.with_params(FK_SQL, { schema.name });
            var foreignkey_relation = yield sql_service.exec_query_params (foreignkey_query);

            foreach (var item in foreignkey_relation) {
                var fk = new ForeignKey();
                fk.name = item[0];
                fk.table = item[1];
                fk.columns = parse_array_result(item[2]);
                fk.fk_table = item[3];
                fk.fk_columns = parse_array_result(item[4]);

                int idx = table_vec.find((table) => {
                    return(table.name == fk.table);
                });

                if (idx == -1) {
                    var new_table = new Table(schema);
                    new_table.name = fk.table;
                    new_table.foreign_keys.append(fk);
                    table_vec.append(new_table);
                    continue;
                }

                table_vec[idx].foreign_keys.append(fk);
            }

            this.tables.clear();
            foreach (var item in table_vec) {

                foreach (var col in item.columns) {
                    foreach (var pk in item.primaty_keys) {
                        if (col.name in pk.columns) {
                            col.is_primarykey = true;
                            break;
                        }
                    }

                    foreach (var fk in item.foreign_keys) {
                        if (col.name in fk.columns) {
                            col.is_foreignkey = true;
                            break;
                        }
                    }
                }


                this.tables.append(item);
            }
        }

        public const string TABLE_LIST = """
    SELECT ta.tablename, cls.reltuples::bigint AS estimate FROM pg_tables ta
    JOIN pg_class cls ON cls.relname = ta.tablename 
    WHERE schemaname=$1;
        """;

        public const string COLUMN_SQL = """
        SELECT cls.relname AS tbl, attname AS col, format_type(a.atttypid, a.atttypmod) AS datatype, NOT attnotnull AS nullable, pg_get_expr(d.adbin, d.adrelid) AS default_value
        FROM   pg_attribute a
        LEFT JOIN pg_catalog.pg_attrdef d ON (a.attrelid, a.attnum) = (d.adrelid, d.adnum)
        LEFT JOIN pg_class cls ON cls.oid = a.attrelid
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = cls.relnamespace
        WHERE  n.nspname = $1
        AND    attnum > 0
        AND    NOT attisdropped
        AND    cls.relkind = 'r'
        ORDER  BY attnum;
        """;
        public const string INDEX_SQL = """
    SELECT cls.relname, rel_cls.relname, ARRAY_AGG(attr.attname) AS indexed_columns, pg_size_pretty(pg_relation_size(cls.relname::regclass)) as size, indisunique, am.amname
    FROM pg_index idx
    JOIN pg_class cls ON idx.indexrelid = cls.oid
    JOIN pg_class rel_cls ON idx.indrelid = rel_cls.oid
    JOIN pg_catalog.pg_attribute attr ON attr.attrelid = rel_cls.oid
    JOIN pg_namespace nsp ON cls.relnamespace = nsp.oid
    JOIN pg_am am ON am.oid = cls.relam
    WHERE nsp.nspname = $1
    AND cls.relkind = 'i'
    AND NOT indisprimary
    AND attr.attnum = ANY(idx.indkey)
    GROUP BY cls.relname, rel_cls.relname, indisunique, am.amname
        """;

        public const string PK_SQL = """
    SELECT 
        con.conname,
        cls1.relname AS table,
        ARRAY_AGG(attr1.attname) AS columns
    FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class cls1 ON con.conrelid = cls1.oid
    JOIN pg_catalog.pg_attribute attr1 ON attr1.attrelid = cls1.oid
    JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace 
    WHERE con.contype = 'p'
        AND attr1.attnum = ANY(con.conkey)
        AND nsp.nspname = $1
    GROUP BY con.oid, con.conname, cls1.relname;
    """;

        public const string FK_SQL = """
    SELECT 
        con.conname,
        cls1.relname AS src_table,
        ARRAY_AGG(attr1.attname) AS src_columns,
        cls2.relname AS dest_table,
        ARRAY_AGG(attr2.attname) AS dest_columns,
        ARRAY_AGG(attr1.attnum) AS src_columns_num
    FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class cls1 ON con.conrelid = cls1.oid
    JOIN pg_catalog.pg_class cls2 ON con.confrelid = cls2.oid
    JOIN pg_catalog.pg_attribute attr1 ON attr1.attrelid = cls1.oid
    JOIN pg_catalog.pg_attribute attr2 ON attr2.attrelid = cls2.oid
    JOIN pg_catalog.pg_namespace nsp ON con.connamespace = nsp.oid
    WHERE 
        nsp.nspname = $1
        AND con.contype = 'f'
        AND con.confrelid > 0
        AND attr1.attnum = ANY(con.conkey)
        AND attr2.attnum = ANY(con.confkey)
    GROUP BY nsp.nspname, con.oid, con.conname, cls1.relname, cls2.relname
    ORDER BY src_table, src_columns_num;
    """;
    }
}
