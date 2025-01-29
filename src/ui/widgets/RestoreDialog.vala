namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/restore-dialog.ui")]
    public class RestoreDialog : Adw.Dialog {
        public static string[] FORMATS = {
            "custom",
            "directory",
            "tar"
        };

        public static string[] SECTIONS = {
            "everything",
            "schema only",
            "data only",
        };

        public Connection conn { get; set; }
        public string format { get;  set; default = "custom"; }
        public string section { get;  set; default = "everything"; }
        public bool clean { get;  set; default = false; }
        public bool create { get; set; default = false; }

        public Gtk.StringList formats { get;  set; default = new Gtk.StringList(RestoreDialog.FORMATS); }
        public Gtk.StringList sections { get; set; default = new Gtk.StringList(RestoreDialog.SECTIONS); }

        public signal void on_restore (Connection conn, Vec<string> options);

        public ConnectionViewModel viewmodel { get; set; }

        public RestoreDialog(ConnectionViewModel viewmodel){
            Object(viewmodel: viewmodel);
        }

        construct {
            var expresion = new Gtk.PropertyExpression(typeof (Connection), null, "name");
            database_row.expression = expresion;

            database_row.notify["selected-item"].connect((item) => {
                this.conn = viewmodel.connections.find((conn) => {
                    return conn == database_row.selected_item;
                });
            });

            format_row.notify["selected-item"].connect((item) => {
                this.format = (format_row.selected_item as Gtk.StringObject) ? .string;
            });

            section_row.notify["selected-item"].connect((item) => {
                this.section = (section_row.selected_item as Gtk.StringObject) ? .string;
            });
        }

        public bool is_choose_directory (){
            return(this.format == "directory");
        }

        public string get_extension (){
            if (this.format == "custom") {
                return(".dump");
            } else if (this.format == "directory") {
                return("");
            } else if (this.format == "tar") {
                return(".tar");
            }

            return(".dump");
        }

        [GtkCallback]
        private void on_do_restore_click (){
            var vec = new Vec<string>();
            vec.append("--format");
            vec.append(this.format);

            if (section == "everything") {
                // add not thing
            } else if (section == "schema only") {
                vec.append("--schema-only");
            } else if (section == "data only") {
                vec.append("--data-only");
            } else {
                debug("Invalid section: %s", section);
            }

            if (clean) {
                vec.append("--clean");
            }

            if (create) {
                vec.append("--create");
            }

            on_restore(conn, vec);
        }

        [GtkChild]
        private unowned Adw.ComboRow database_row;

        [GtkChild]
        private unowned Adw.ComboRow format_row;

        [GtkChild]
        private unowned Adw.ComboRow section_row;
    }
}
