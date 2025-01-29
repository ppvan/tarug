using Gtk;
using Adw;
using GtkSource;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/where-entry.ui")]
    public class WhereEntry : Gtk.Box {
        // private GtkSource.

        private LanguageManager lang_manager;
        private StyleSchemeManager style_manager;
        private Application app;
        private GtkSource.Completion completion;
        private TableColumnCompletionService provider;
        private TableDataViewModel table_data_viewmodel;


        public WhereEntry(){
            Object();
        }

        construct {
            this.app = autowire<Application>();
            this.table_data_viewmodel = autowire<TableDataViewModel>();
            default_setttings();

            this.buffer.insert_text.connect((ref pos, text, len) => {
                if (text == "\n") {
                    this.filter_query.begin();
                    Signal.stop_emission_by_name(this.buffer, "insert_text");
                } else if (text == "\t") {
                    this.editor.move_focus(Gtk.DirectionType.RIGHT);
                    Signal.stop_emission_by_name(this.buffer, "insert_text");
                }
            });

            this.table_data_viewmodel.bind_property("where_query", this.buffer, "text", BindingFlags.BIDIRECTIONAL);
        }


        [GtkCallback]
        private async void filter_query (){
            table_data_viewmodel.where_query = this.buffer.text;
            yield table_data_viewmodel.reload_data ();
        }

        // [GtkCallback]
        // private void on_filter_changed(Gtk.Editable entry) {

        // }

        private void default_setttings (){
            lang_manager = LanguageManager.get_default();
            style_manager = StyleSchemeManager.get_default();
            var lang = lang_manager.get_language("sql");
            buffer.language = lang;
            completion = editor.get_completion();
            completion.select_on_show = true;
            completion.page_size = 8;
            provider = new TableColumnCompletionService();
            completion.add_provider(provider);


            app.style_manager.bind_property("dark", buffer, "style_scheme", BindingFlags.SYNC_CREATE, (binding, from, ref to) => {
                var is_dark = from.get_boolean();
                if (is_dark) {
                    var scheme = style_manager.get_scheme("Adwaita-dark");
                    to.set_object(scheme);
                } else {
                    var scheme = style_manager.get_scheme("Adwaita");
                    to.set_object(scheme);
                }

                return(true);
            });
        }

        [GtkChild]
        private unowned GtkSource.Buffer buffer;

        [GtkChild]
        private unowned GtkSource.View editor;
    }
}
