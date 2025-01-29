using Gee;

namespace Tarug {
/* View here is database view (virtual tables), not UI */
    public class ViewViewModel : BaseViewModel {
        public ObservableList<View> views { get; set; default = new ObservableList<View> (); }
        public View ? selected_view { get; set; }

        public Schema schema { get; private set; }
        public SQLService sql_service { get; private set; }


        public ViewViewModel(SQLService service){
            base();
            this.sql_service = service;
            this.notify["selected-view"].connect(() => {
                EventBus.instance().selected_view_changed(selected_view);
            });

            EventBus.instance().schema_changed.connect((schema) => {
                views.clear();
                load_views.begin(schema);
            });
        }

        public void select_view (View ? view){
            if (view == null) {
                return;
            }


            debug("selecting view %s", view.name);
            selected_view = view;
        }

        public void select_index (int index){
            if (index < 0 || index >= views.size) {
                return;
            }

            debug("selecting view %s", views[index].name);
            selected_view = views[index];
        }

        public bool is_view (string view_name){
            return(views.find((view) => {
                return view.name == view_name;
            }) != null);
        }

        public async string get_viewdef (string view_name){
            debug("loading views");
            var query = new Query.with_params(VIEW_DEF, { view_name });
            try {
                var relation = yield sql_service.exec_query_params (query);

                if (relation.rows > 0) {
                    return(relation[0][0]);
                }
            } catch (tarugError err) {
                debug("Error: " + err.message);
            }

            return("Error: can't get view def for " + view_name);
        }

        private async void load_views (Schema schema) throws tarugError {
            debug("loading views");
            var query = new Query.with_params(VIEW_LIST, { schema.name });
            var relation = yield sql_service.exec_query_params (query);

            var view_vec = new Vec<View>();

            foreach (var item in relation) {
                var view = new View(schema);
                view.name = item[0];
                view.defs = item[1];
                view_vec.append(view);
            }

            var columns_query = new Query.with_params(COLUMN_SQL, { schema.name });
            var columns_relation = yield sql_service.exec_query_params (columns_query);

            foreach (var item in columns_relation) {
                var col = new Column();
                col.table = item[0];
                col.name = item[1];
                col.column_type = item[2];
                col.nullable = item[3] == "t" ? true : false;
                col.default_val = item[4];

                int index = view_vec.find((table) => {
                    return(table.name == col.table);
                });

                if (index == -1) {
                    var new_table = new View(schema);
                    new_table.name = col.table;
                    new_table.columns.append(col);
                    view_vec.append(new_table);
                    continue;
                }

                view_vec[index].columns.append(col);
            }

            views.clear();
            views.append_all(view_vec.as_list());
            debug("%d views loaded", views.size);
        }

        public const string VIEW_LIST = """
    SELECT pv.viewname, pv.definition FROM pg_views pv WHERE schemaname = $1;
        """;

        public const string COLUMN_SQL = """
    SELECT cls.relname AS tbl, attname AS col, format_type(a.atttypid, a.atttypmod) AS datatype, attnotnull, pg_get_expr(d.adbin, d.adrelid) AS default_value
    FROM   pg_attribute a
    LEFT JOIN pg_catalog.pg_attrdef d ON (a.attrelid, a.attnum) = (d.adrelid, d.adnum)
    LEFT JOIN pg_class cls ON cls.oid = a.attrelid
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = cls.relnamespace
    WHERE  n.nspname = $1
    AND    attnum > 0
    AND    NOT attisdropped
    AND    cls.relkind = 'v'
    ORDER  BY attnum;
        """;

        public const string VIEW_DEF = """
        SELECT pg_get_viewdef($1);
        """;
    }
}
