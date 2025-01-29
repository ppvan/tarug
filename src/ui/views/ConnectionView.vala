namespace Psequel {
    [GtkTemplate(ui = "/me/ppvan/psequel/gtk/connection-view.ui")]
    public class ConnectionView : Adw.Bin {

        // Data source
        public ConnectionViewModel viewmodel { get; private set; }
        public Connection ? selected_connection { get; set; }

        // UI
        BindingGroup bindings;
        const ActionEntry[] ACTION_ENTRIES = {
            { "connect", on_connect_connection },
            { "dupplicate", on_dupplicate_connection },
            { "delete", on_remove_connection },
        };
        private Adw.AlertDialog err_dialog;

        public ConnectionView(Application app){
            Object();
        }

        // Connect event.
        construct {
            setup_paned(paned);
            this.viewmodel = autowire<ConnectionViewModel> ();

            this.err_dialog = new Adw.AlertDialog("Connection Failed", null) {
                default_response = "okay",
            };
            this.err_dialog.add_response("okay", "OK");

            var action_group = new SimpleActionGroup();
            action_group.add_action_entries(ACTION_ENTRIES, this);
            this.insert_action_group("conn", action_group);

            set_up_bindings();
        }

        // [GtkCallback]
        // public void save_connections () {
        // viewmodel.save_connections ();
        // }

        [GtkCallback]
        public void add_new_connection (){
            viewmodel.new_connection();
        }

        [GtkCallback]
        public void active_connection (Gtk.ListView view, uint pos){
            viewmodel.active_connection.begin(viewmodel.selected_connection);
        }

        [GtkCallback]
        public void on_connect_clicked (Gtk.Button btn){
            viewmodel.active_connection.begin(viewmodel.selected_connection);
        }

        [GtkCallback]
        private void on_entry_activated (Gtk.Entry entry){
            on_connect_connection();
        }

        [GtkCallback]
        private void on_text_changed (Gtk.Editable editable){
            viewmodel.save_connections();
        }

        [GtkCallback]
        private void on_cert_file_chooser (Gtk.EntryIconPosition pos){
            if (pos != Gtk.EntryIconPosition.SECONDARY) {
                return;
            }

            open_file_dialog.begin();
        }

        [GtkCallback]
        private void on_cert_entry_activate (Gtk.Entry entry){
            open_file_dialog.begin();
        }

        [GtkCallback]
        private void on_switch_changed (){
            viewmodel.save_connections();
        }

        // [GtkAction]
        private void on_dupplicate_connection (){
            viewmodel.dupplicate_connection(viewmodel.selected_connection);
        }

        // [GtkAction]
        private void on_connect_connection (){
            viewmodel.active_connection.begin(viewmodel.selected_connection);
        }

        // [GtkAction]
        private void on_remove_connection (){
            viewmodel.remove_connection(viewmodel.selected_connection);
        }

        private bool from_selected (Binding binding, Value from, ref Value to){
            uint pos = from.get_uint();

            if (pos != Gtk.INVALID_LIST_POSITION) {
                to.set_object(selection_model.get_item(pos));
            }

            return(true);
        }

        private bool to_selected (Binding binding, Value from, ref Value to){
            Connection conn = (Connection) from.get_object();
            for (uint i = 0; i < selection_model.get_n_items(); i++) {
                if (selection_model.get_item(i) == conn) {
                    to.set_uint(i);
                    return(true);
                }
            }

            to.set_uint(Gtk.INVALID_LIST_POSITION);

            return(true);
        }

        private async void open_file_dialog (string title = "Choose certificate file"){
            var filter = new Gtk.FileFilter();
            filter.add_mime_type("application/x-x509-ca-cert");

            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(filter);

            var window = (Window) get_parrent_window(this);

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = File.new_for_path(Environment.get_home_dir()),
                title = title,
                initial_name = "server.cert",
                default_filter = filter,
                filters = filters
            };

            try {
                var file = yield file_dialog.open (window, null);

                var path = file.get_path();

                this.viewmodel.selected_connection.cert_path = path;
            } catch (Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };
                window.add_toast(toast);
            }
        }

        private void set_up_bindings (){
            // Save ref so it does not be cleaned by GC
            this.bindings = create_form_bind_group();

            viewmodel.bind_property("selected-connection", this.bindings, "source", BindingFlags.SYNC_CREATE);
            viewmodel.bind_property("is-connectting", connect_btn, "sensitive", INVERT_BOOLEAN | SYNC_CREATE);
            viewmodel.bind_property("err-msg", this.err_dialog, "body", SYNC_CREATE);
            viewmodel.notify["current-state"].connect(() => {
                if (viewmodel.current_state == ConnectionViewModel.State.ERROR) {
                    this.err_dialog.present(this);
                }
            });

            selection_model.bind_property("selected", viewmodel, "selected-connection",
                                          DEFAULT | BIDIRECTIONAL, from_selected, to_selected);
            password_entry.bind_property("text",
                                         password_entry,
                                         "show-peek-icon",
                                         BindingFlags.SYNC_CREATE,
                                         (binding, from_value, ref to_value) => {
                string text = from_value.get_string();
                to_value.set_boolean(text.length > 0);

                return(true);
            });
        }

        private BindingGroup create_form_bind_group (){
            var binddings = new BindingGroup();
            // debug ("set_up connection form bindings group");
            binddings.bind("name", name_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("host", host_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("port", port_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("user", user_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("password", password_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("database", database_entry, "text", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("use_ssl", ssl_switch, "active", SYNC_CREATE | BIDIRECTIONAL);
            binddings.bind("cert_path", cert_path, "text", SYNC_CREATE | BIDIRECTIONAL);
            // debug ("set_up binddings done");


            return(binddings);
        }

        [GtkChild]
        private unowned Gtk.SingleSelection selection_model;
        [GtkChild]
        private unowned Gtk.Paned paned;

        [GtkChild]
        private unowned Gtk.Button connect_btn;

        [GtkChild]
        private unowned Gtk.Entry name_entry;

        [GtkChild]
        private unowned Gtk.Entry host_entry;
        [GtkChild]
        private unowned Gtk.Entry port_entry;
        [GtkChild]
        private unowned Gtk.Entry user_entry;
        [GtkChild]
        private unowned Gtk.PasswordEntry password_entry;

        [GtkChild]
        private unowned Gtk.Entry database_entry;

        [GtkChild]
        private unowned Gtk.Entry cert_path;

        [GtkChild]
        private unowned Gtk.Switch ssl_switch;
    }



    [GtkTemplate(ui = "/me/ppvan/psequel/gtk/connection-row.ui")]
    public class ConnectionRow : Gtk.Box {
        public Connection item { get; set; }
        public uint pos { get; set; }


        [GtkCallback]
        public void on_right_clicked (){
            var list_view = this.parent.parent as Gtk.ListView;
            list_view.model.select_item(pos, true);

            popover.popup();
        }

        [GtkChild]
        private unowned Gtk.PopoverMenu popover;
    }
}
