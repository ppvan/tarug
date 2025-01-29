using GtkSource;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/view-structure-view.ui")]
    public class ViewStructureView : Gtk.Box {
        public ViewViewModel view_viewmodel { get; set; }
        public ListModel columns { get; private set; }

        public ViewStructureView(){
            Object();
        }

        construct {
            this.view_viewmodel = autowire<ViewViewModel> ();

            view_viewmodel.notify["selected-view"].connect(() => {
                var obs_list = new ObservableList<Column> ();
                obs_list.append_all(view_viewmodel.selected_view.columns.as_list());

                columns = obs_list;
                buffer.text = view_viewmodel.selected_view.defs;
            });

            var app = autowire<Application> ();

            var lang = LanguageManager.get_default().get_language("sql");
            buffer.language = lang;

            app.style_manager.bind_property("dark", buffer, "style_scheme", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                var is_dark = from.get_boolean();
                if (is_dark) {
                    var scheme = StyleSchemeManager.get_default().get_scheme("Adwaita-dark");
                    to.set_object(scheme);
                } else {
                    var scheme = StyleSchemeManager.get_default().get_scheme("Adwaita");
                    to.set_object(scheme);
                }

                return(true);
            });
        }

        [GtkCallback]
        private void on_copy_clicked (){
            clipboard_push(view_viewmodel.selected_view.defs);

            var window = get_parrent_window(this);
            Adw.Toast toast = new Adw.Toast(view_viewmodel.selected_view.name + " view definitions copied"){
                timeout = 1,
            };
            window.add_toast(toast);
        }

        private void clipboard_push (string text){
            var primary = Gdk.Display.get_default();
            var clipboard = primary.get_clipboard();

            clipboard.set_text(text);
        }

        [GtkChild]
        private unowned GtkSource.Buffer buffer;
    }
}
