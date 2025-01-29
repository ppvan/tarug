using Gdk;
using Csv;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/datacell.ui")]
    public class DataCell : Adw.Bin {
        private Relation.Row current_row;
        private int current_index;
        public bool is_busy { get; set; default = false; }
        const ActionEntry[] ACTION_ENTRIES = {
            { "copy", on_cell_copy },
            { "edit", on_cell_edit },
            { "row-copy", on_row_copy },
        };



        public DataCell(){
            Object();
        }

        construct {
            var action_group = new SimpleActionGroup();
            action_group.add_action_entries(ACTION_ENTRIES, this);
            this.insert_action_group("schema", action_group);
        }


        public void bind_data (Tarug.Relation.Row row, int index){
            this.current_row = row;
            this.current_index = index;
            var val = row[index];
            this.label.text = val;
            this.label.min_chars = val.length + 1;
        }

        public void unbind_data (Tarug.Relation.Row row){
            this._is_busy = false;
        }

        [GtkCallback]
        public void on_right_clicked (){
            popover.popup();
        }

        // [GtkAction]
        private void on_cell_copy (){
            // viewmodel.dupplicate_connection (viewmodel.selected_connection);
            debug("on_cell_copy");

            var primary = Gdk.Display.get_default();
            var clipboard = primary.get_clipboard();

            clipboard.set_text(this.current_row[current_index]);
        }

        // [GtkAction]
        private void on_row_copy (){
            // viewmodel.active_connection.begin (viewmodel.selected_connection);
            StringBuilder builder = new StringBuilder();

            for (int i = 0; i < current_row.size - 1; i++) {
                var col = current_row[i];
                builder.append_printf("%s, ", Csv.quote(col));
            }

            var last_col = current_row[current_row.size - 1];
            builder.append_printf("%s", Csv.quote(last_col));
            var row_as_csv = builder.free_and_steal();

            this.clipboard_push(row_as_csv);
        }

        private void clipboard_push (string text){
            var primary = Gdk.Display.get_default();
            var clipboard = primary.get_clipboard();

            clipboard.set_text(text);
        }

        private void on_cell_edit (){
            // viewmodel.active_connection.begin (viewmodel.selected_connection);
            debug("on_cell_edit");
            var app = autowire<Application>();
            var window = app.active_window;

            var dialog = new EditRowDialog(current_row);

            dialog.present(window);
        }

        [GtkChild]
        private unowned Gtk.Inscription label;

        [GtkChild]
        private unowned Gtk.PopoverMenu popover;
    }
}
