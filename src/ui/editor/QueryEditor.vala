using GtkSource;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/query-editor.ui")]
    public class QueryEditor : Adw.Bin {
        const string LIGHT_TAG = "query-block-light";
        const string DARK_TAG = "query-block-dark";

        delegate void ChangeStateFunc (SimpleAction action, Variant ? new_state);

        public ExportService export_service { get; set; }
        public QueryViewModel query_viewmodel { get; set; }


        public QueryHistoryViewModel query_history_viewmodel { get; set; }
        public Query ? selected_query { get; set; }

        private GLib.SimpleAction auto_uppercase;
        private GLib.SimpleAction auto_exec_history;


        private GtkSource.Completion completion;
        private SQLCompletionService provider;


        private LanguageManager lang_manager;
        private StyleSchemeManager style_manager;

        private Settings ? settings;
        private Application ? app;

        public class QueryEditor(){
            Object();
        }

        construct {
            this.export_service = autowire<ExportService> ();
            this.query_viewmodel = autowire<QueryViewModel> ();
            this.query_history_viewmodel = autowire<QueryHistoryViewModel> ();
            this.settings = autowire<Settings> ();
            this.app = autowire<Application> ();

            default_setttings();
            selection_model.bind_property("selected", this, "selected-query", BindingFlags.BIDIRECTIONAL, from_selected, to_selected);
            spinner.bind_property("spinning", run_query_btn, "sensitive", BindingFlags.INVERT_BOOLEAN);

            buffer.changed.connect(highlight_current_query);
            buffer.cursor_moved.connect(highlight_current_query);

            create_action_group();
            setup_paned(paned);
        }


        [GtkCallback]
        private void run_query_cb (Gtk.Button btn){
            query_viewmodel.run_selected_query.begin();
        }

        [GtkCallback]
        private void on_clear_history (Gtk.Button btn){
            query_history_viewmodel.clear_history.begin();
            popover.hide();
        }

        [GtkCallback]
        private void on_query_history_exec (Gtk.ListView view, uint pos){
            var history_query = (Query) selection_model.get_item(pos);
            debug("History activated, exec: %s", history_query.sql);
            query_history_viewmodel.exec_history.begin(history_query);

            var text = history_query.sql ?? "error";
            clear_and_insert(buffer, text);

            popover.hide();
        }

        /** Clear and insert insteal of manipulate .text to keep undo possible */
        private void clear_and_insert (Gtk.TextBuffer buf, string text){
            Gtk.TextIter iter1;
            buffer.get_start_iter(out iter1);

            Gtk.TextIter iter2;
            buffer.get_end_iter(out iter2);

            if (!iter1.equal(iter2)) {
                buffer.delete_range(iter1, iter2);
            }

            // buffer.insert (ref iter1, );
            buffer.insert_at_cursor(text, text.length);
        }

        private void default_setttings (){
            lang_manager = LanguageManager.get_default();
            style_manager = StyleSchemeManager.get_default();

            completion = editor.get_completion();
            completion.select_on_show = true;
            completion.page_size = 8;
            provider = new SQLCompletionService();
            completion.add_provider(provider);

            var lang = lang_manager.get_language("sql");
            buffer.language = lang;

            // rgba(104, 109, 224,1.0)
            var light_tag = new Gtk.TextTag(LIGHT_TAG);
            light_tag.background_rgba = { 237 / 255f, 255 / 255f, 255 / 255f, 0.9f };

            // rgba(149, 175, 192,1.0)
            var dark_tag = new Gtk.TextTag(DARK_TAG);
            dark_tag.background_rgba = { 149 / 255f, 175 / 255f, 192 / 255f, 0.2f };
            // tag.background = "sidebar_backdrop_color";
            // rgba(52, 73, 94,1.0)
            // rgb(237, 255, 255)
            buffer.tag_table.add(light_tag);
            buffer.tag_table.add(dark_tag);


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

        private void highlight_current_query (){
            var raw_query = buffer.text;
            var stmts = PgQuery.split_with_scanner(raw_query);
            this.clear_highlight();

            for (var i = 0; i < stmts.n_stmts; i++) {
                if (stmts.error != null) {
                    return;
                }
                var current_statement = stmts.stmts[i];

                var start = current_statement->stmt_location;
                var end = start + current_statement->stmt_len;

                // debug ("[%d, %d], %s", token.location, token.end, token.value);

                Gtk.TextIter iter1;
                Gtk.TextIter iter2;

                // buffer.get_start_iter (out iter1);
                // buffer.get_end_iter (out iter2);
                // buffer.remove_tag_by_name (TAG_NAME, iter1, iter2);

                buffer.get_iter_at_offset(out iter1, start);
                buffer.get_iter_at_offset(out iter2, end);

                if (start < buffer.cursor_position && buffer.cursor_position <= end + 1) {
                    // Double-check with strict mode.
                    string statement = buffer.get_text(iter1, iter2, false);
                    if (!is_sql_query(statement)) {
                        return;
                    }


                    if (app.style_manager.dark) {
                        buffer.apply_tag_by_name(DARK_TAG, iter1, iter2);
                    } else {
                        buffer.apply_tag_by_name(LIGHT_TAG, iter1, iter2);
                    }

                    query_viewmodel.selected_query_changed(statement);
                } else {
                    buffer.remove_tag_by_name(DARK_TAG, iter1, iter2);
                    buffer.remove_tag_by_name(LIGHT_TAG, iter1, iter2);
                }
            }
        }

        private inline void clear_highlight (){
            Gtk.TextIter start;
            Gtk.TextIter end;

            buffer.get_start_iter(out start);
            buffer.get_end_iter(out end);
            buffer.remove_tag_by_name(DARK_TAG, start, end);
            buffer.remove_tag_by_name(LIGHT_TAG, start, end);
        }

        private void create_action_group (){
            var group = new SimpleActionGroup();
            this.insert_action_group("editor", group);

            auto_uppercase = boolean_state_factory("auto-uppercase");
            auto_exec_history = boolean_state_factory("auto-exec-history");

            group.add_action((owned) auto_uppercase);
            group.add_action((owned) auto_exec_history);

            this.insert_action_group("editor", group);
        }

        private SimpleAction boolean_state_factory (string name){
            bool init = settings.get_boolean(name);
            var action = new SimpleAction.stateful(name, null, new Variant.boolean(init));
            action.activate.connect(toggle_boolean);
            return(action);
        }

        private void toggle_boolean (Action action, Variant ? parameter){
            Variant state = action.state;
            bool old_state = state.get_boolean();
            bool new_state = !old_state;
            action.change_state(new_state);
            settings.set_boolean(action.name, new_state);
        }

        private bool from_selected (Binding binding, Value from, ref Value to){
            uint pos = from.get_uint();

            if (pos != Gtk.INVALID_LIST_POSITION) {
                to.set_object(selection_model.get_item(pos));
            }

            return(true);
        }

        private bool to_selected (Binding binding, Value from, ref Value to){
            Query query = (Query) from.get_object();
            for (uint i = 0; i < selection_model.get_n_items(); i++) {
                if (selection_model.get_item(i) == query) {
                    to.set_uint(i);
                    return(true);
                }
            }

            to.set_uint(Gtk.INVALID_LIST_POSITION);

            return(true);
        }

        [GtkCallback]
        private void on_export_csv (Gtk.Button btn){
            export_to_csv_file.begin();
        }

        private async void export_to_csv_file (string title = "Open File"){
            var filter = new Gtk.FileFilter();
            // filter.add_pattern ("*.csv");
            filter.add_mime_type("text/csv");
            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(filter);

            var window = (Window) get_parrent_window(this);

            var now = new GLib.DateTime.now();
            var local_time = now.format("%F-%H:%M:%S");
            var initial_name = @"query-export-$(local_time).csv";

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = GLib.File.new_for_path(Environment.get_home_dir()),
                title = title,
                default_filter = filter,
                filters = filters,
                initial_name = initial_name,
            };

            try {
                var dest = yield file_dialog.save (window, null);

                yield export_service.export_csv (dest, query_history_viewmodel.current_relation);
            } catch (GLib.Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };

                window.add_toast(toast);
            }
        }

        [GtkChild]
        private unowned GtkSource.View editor;

        [GtkChild]
        private unowned Gtk.Button run_query_btn;

        [GtkChild]
        private unowned Gtk.Spinner spinner;


        [GtkChild]
        private unowned GtkSource.Buffer buffer;

        [GtkChild]
        private unowned Gtk.Paned paned;

        [GtkChild]
        private unowned Gtk.SingleSelection selection_model;

        [GtkChild]
        private unowned Gtk.Popover popover;
    }
}
