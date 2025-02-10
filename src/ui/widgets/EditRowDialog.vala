namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/edit-row.ui")]
    public class EditRowDialog : Adw.Dialog {
        private TableDataViewModel tabledata_viewmodel;
        private Relation.Row current_row;
        private Vec<TableField> fields;

        public bool has_changed { get; set; default = false; }

        public EditRowDialog(Relation.Row current_row){
            Object();
            this.current_row = current_row;
        }

        construct {
            this.tabledata_viewmodel = autowire<TableDataViewModel> ();
        }


        public new void present (Gtk.Widget ? parent){
            var table = this.tabledata_viewmodel.selected_table;
            this.fields = new Vec<TableField>.with_capacity (table.columns.length);

            int index = 0;
            foreach (var col in table.columns) {
                var label = col.is_primarykey ? new Gtk.Label(@"$(col.name)*") : new Gtk.Label(col.name);

                label.halign = Gtk.Align.START;
                grid.attach(label, 0, index, 1, 1);

                var entry = new Gtk.Entry();
                if (col.is_primarykey) {
                    entry.sensitive = false;
                    entry.tooltip_text = "Update primary key values is not supported";
                }
                var default_value = (current_row.get_by_header(col.name)) ?? "";
                entry.changed.connect(() => {
                    check_changed();
                });


                var field = new TableField(col, default_value, entry);
                fields.append(field);

                entry.text = default_value;
                grid.attach(entry, 1, index, 3, 1);

                index++;
            }

            base.present(parent);
        }

        private void check_changed (){
            if (this.fields == null) {
                return;
            }

            foreach (var item in this.fields) {
                if (item.old_value != item.new_value) {
                    has_changed = true;
                }
            }
        }

        [GtkCallback]
        private async void update_row (Gtk.Button btn){
            if (this.fields == null) {
                return;
            }

            this.can_close = false;
            //  yield this.tabledata_viewmodel.update_row (this.fields);

            this.can_close = true;
            this.close();
        }

        [GtkCallback]
        private void cancel_update (Gtk.Button btn){
            this.close();
        }

        [GtkChild]
        private unowned Gtk.Grid grid;
    }

    public class TableField : Object {
        public Column column { get; set; }
        public string old_value { get; set; }
        public string new_value { get; set; default = ""; }
        public Gtk.Entry field_entry { get; set; }

        public TableField(Column col, string old_value, Gtk.Entry entry){
            base();

            this.column = col;
            this.old_value = old_value;
            this.field_entry = entry;

            entry.bind_property("text", this, "new_value", BindingFlags.BIDIRECTIONAL);
        }
    }
}
