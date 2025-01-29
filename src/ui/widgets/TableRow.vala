using Gtk;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/table-row.ui")]
    class TableRow : Gtk.Box {
        public string content { get; set; default = ""; }
        public string icon_name { get; set; default = ""; }

        private TableDataViewModel tabledata_viewmodel { get; set; }
        private ViewViewModel view_model { get; set; }


        const ActionEntry[] ACTION_ENTRIES = {
            { "copy", on_row_copy },
            { "copy_ddl", on_table_ddl_copy },
            { "refresh", on_row_refresh },
        };

        public TableRow(){
            Object();
        }

        construct {
            var action_group = new SimpleActionGroup();
            action_group.add_action_entries(ACTION_ENTRIES, this);
            this.insert_action_group("sidebar", action_group);
            tabledata_viewmodel = autowire<TableDataViewModel> ();
            view_model = autowire<ViewViewModel>();
        }


        [GtkCallback]
        public void on_right_clicked (){
            popover.popup();
        }

        // [GtkAction]
        private void on_row_copy (){
            clipboard_push(this.content);

            var window = get_parrent_window(this);
            Adw.Toast toast = new Adw.Toast("Table name copied"){
                timeout = 1,
            };
            window.add_toast(toast);
        }

        // [GtkAction]
        private void on_table_ddl_copy (){
            if (view_model.is_view(this.content)) {
                view_model.get_viewdef.begin(this.content, (obj, res) => {
                    var def = view_model.get_viewdef.end(res);
                    clipboard_push(def);

                    var window = get_parrent_window(this);
                    Adw.Toast toast = new Adw.Toast(this.content + " view definitions copied"){
                        timeout = 1,
                    };
                    window.add_toast(toast);
                });
            } else {}
        }

        private void on_row_refresh (){
            // General idea: Loop throught the single selection model
            // Assume the content of the label item is the same as the model-item.name
            // and the list view is a single selection.

            var listview_type = GLib.Type.from_name("GtkListView");
            Gtk.ListView view = this.get_ancestor(listview_type) as Gtk.ListView;
            Gtk.SingleSelection model = view.model as Gtk.SingleSelection;

            uint n = model.get_n_items();

            for (uint i = 0; i < n; i++) {
                Object obj = model.model.get_item(i);
                Value v = {};
                obj.get_property("name", ref v);
                string key = v.get_string();

                if (key == this.content) {
                    model.select_item(i, true);
                    view.activate(i);

                    var window = get_parrent_window(this);
                    Adw.Toast toast = new Adw.Toast(@"\"$content\" Refreshed"){
                        timeout = 1,
                    };
                    window.add_toast(toast);

                    break;
                }
            }



            // view.activate();
        }

        private void clipboard_push (string text){
            var primary = Gdk.Display.get_default();
            var clipboard = primary.get_clipboard();

            clipboard.set_text(text);
        }

        [GtkChild]
        private unowned Gtk.Popover popover;
    }
}
