namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/table-structure-view.ui")]
    public class TableStructureView : Gtk.Box {
        public TableViewModel table_viewmodel { get; private set; }

        public ListModel columns { get; private set; }
        public ListModel indexes { get; private set; }
        // public Gtk.FilterListModel fks { get; private set; }
        // public Gtk.StringFilter filter { get; private set; }

        public TableStructureView(){
            Object();
        }

        construct {
            this.table_viewmodel = autowire<TableViewModel> ();

            // this.filter       = new Gtk.StringFilter(null);
            // filter.expression = new Gtk.PropertyExpression(typeof(BaseType), null, "table");
            // filter.match_mode = Gtk.StringFilterMatchMode.EXACT;
            // this.columns      = new Gtk.FilterListModel(this.tablestructure_viewmodel.columns, filter);
            // this.indexes      = new Gtk.FilterListModel(this.tablestructure_viewmodel.indexes, filter);
            // this.fks          = new Gtk.FilterListModel(this.tablestructure_viewmodel.foreign_keys, filter);
            // filter.search     = "";

            table_viewmodel.notify["selected-table"].connect(() => {
                var table = table_viewmodel.selected_table;
                var obs_list = new ObservableList<Column> ();
                obs_list.append_all(table.columns.as_list());
                columns = obs_list;

                var indexes_list = new ObservableList<Index> ();
                indexes_list.append_all(table.indexes.as_list());
                indexes = indexes_list;
            });
        }
    }
}
