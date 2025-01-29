namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/schema-view.ui")]
    public class SchemaView : Adw.Bin {
        public SchemaViewModel schema_viewmodel { get; set; }
        public TableViewModel table_viewmodel { get; set; }
        public ViewViewModel view_viewmodel { get; set; }
        public NavigationService navigation_service { get; set; }

        public string view_mode { get; set; }

        public signal void request_logout ();

        public SchemaView(){
            Object();
        }

        construct {
            setup_paned(paned);
            this.schema_viewmodel = autowire<SchemaViewModel> ();
            this.table_viewmodel = autowire<TableViewModel> ();
            this.view_viewmodel = autowire<ViewViewModel> ();
            this.navigation_service = autowire<NavigationService> ();



            sql_views.bind_property("visible-child-name", this, "view-mode", DEFAULT);

            dropdown.notify["selected"].connect(() => {
                if (dropdown.selected == Gtk.INVALID_LIST_POSITION) {
                    return;
                }

                schema_viewmodel.select_index((int) dropdown.selected);
            });
            table_selection.notify["selected"].connect(() => {
                var table = table_selection.get_selected_item() as Table;
                table_viewmodel.select_table((Table) table);
            });
            view_selection.notify["selected"].connect(() => {
                var view = view_selection.get_selected_item() as View;
                view_viewmodel.select_view((View) view);
            });

            EventBus.instance().schema_reload.connect_after(() => {
                var window = get_parrent_window(this);
                Adw.Toast toast;
                toast = new Adw.Toast("Schema Reloaded"){
                    timeout = 1,
                };
                window.add_toast(toast);
            });

            var table_name_expression = new Gtk.PropertyExpression(typeof (Table), null, "name");
            var view_name_expression = new Gtk.PropertyExpression(typeof (View), null, "name");

            var table_name_sorter = new Gtk.StringSorter(table_name_expression);
            var view_name_sorter = new Gtk.StringSorter(view_name_expression);

            dropdown.expression = new Gtk.PropertyExpression(typeof (Schema), null, "name");
            table_filter.expression = new Gtk.PropertyExpression(typeof (Table), null, "name");
            table_sort_model.sorter = table_name_sorter;
            view_sort_model.sorter = view_name_sorter;
            view_filter.expression = new Gtk.PropertyExpression(typeof (View), null, "name");
            stack.visible_child_name = "structure-view";
        }


        [GtkChild]
        private unowned Gtk.Paned paned;

        [GtkCallback]
        private void on_table_search (Gtk.SearchEntry entry){
            table_filter.search = entry.text;
        }

        [GtkCallback]
        private void on_view_search (Gtk.SearchEntry entry){
            view_filter.search = entry.text;
        }

        [GtkCallback]
        private void table_search_reveal (){
            search_table_entry.grab_focus();
        }

        [GtkCallback]
        private void view_search_reveal (){
            search_views_entry.grab_focus();
        }

        [GtkCallback]
        private void reload_btn_clicked (Gtk.Button btn){
            btn.sensitive = false;
            EventBus.instance().schema_reload();
            btn.sensitive = true;
        }

        [GtkCallback]
        private void on_tablelist_activate (Gtk.ListView view, uint pos){
            stack.visible_child_name = "data-view";
            // reload_btn_clicked(reload);
        }

        [GtkCallback]
        private void logout_btn_clicked (Gtk.Button btn){
            btn.sensitive = false;
            EventBus.instance().connection_disabled();
            btn.sensitive = true;
        }

        [GtkChild]
        private unowned Gtk.DropDown dropdown;

        [GtkChild]
        private unowned Gtk.SearchEntry search_table_entry;

        [GtkChild]
        private unowned Gtk.SearchEntry search_views_entry;

        [GtkChild]
        private unowned Gtk.StringFilter table_filter;

        [GtkChild]
        private unowned Gtk.SortListModel table_sort_model;

        [GtkChild]
        private unowned Gtk.SortListModel view_sort_model;



        [GtkChild]
        private unowned Gtk.StringFilter view_filter;

        [GtkChild]
        private unowned Gtk.SingleSelection table_selection;

        [GtkChild]
        private unowned Gtk.SingleSelection view_selection;

        [GtkChild]
        private unowned Adw.ViewStack sql_views;

        [GtkChild]
        private unowned Adw.ViewStack stack;
    }
}
