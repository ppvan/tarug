

namespace Tarug {

    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/table-cols.ui")]
    public class TableColumnInfo : Adw.Bin {

        public ObservableList<Column> columns { get; set; }
        // public GLib.ListModel columns {get; set;}

        public TableColumnInfo(){
            Object();
        }

        construct {
            setup_name_col();
            setup_nullable_col();
            setup_datatype_col();
            setup_default_col();
        }


        private void setup_name_col (){
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect((obj) => {
                var listitem = obj as Gtk.ListItem;

                var label = new Gtk.Label(null);
                label.css_classes = { "table-cell" };
                label.halign = Gtk.Align.START;
                listitem.child = label;
            });
            factory.bind.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var item = listitem.item as Column;
                var label = listitem.child as Gtk.Label;

                if (item.is_primarykey) {
                    label.label = @"$(item.name) *";
                    label.tooltip_text = "Primary Key";
                } else {
                    label.label = @"$(item.name)";
                }
            });
            var col = new Gtk.ColumnViewColumn("Column Name", factory);
            col.fixed_width = 250;
            view.append_column(col);
        }

        private void setup_datatype_col (){
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var label = new Gtk.Label(null);
                label.halign = Gtk.Align.START;

                listitem.child = label;
            });
            factory.bind.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var item = listitem.item as Column;
                var label = listitem.child as Gtk.Label;
                label.label = item.column_type;
            });
            var col = new Gtk.ColumnViewColumn("Data Type", factory);
            col.fixed_width = 240;
            view.append_column(col);
        }

        private void setup_nullable_col (){
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var label = new Gtk.Label(null);
                listitem.child = label;
            });
            factory.bind.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var item = listitem.item as Column;
                var label = listitem.child as Gtk.Label;
                label.label = item.nullable ? "YES" : "NO";
            });
            var col = new Gtk.ColumnViewColumn("Nullable", factory);
            col.fixed_width = 120;

            view.append_column(col);
        }

        private void setup_default_col (){
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var label = new Gtk.Label(null);
                label.halign = Gtk.Align.END;
                label.margin_end = 4;
                label.margin_start = 4;
                listitem.child = label;
            });
            factory.bind.connect((obj) => {
                var listitem = obj as Gtk.ListItem;
                var item = listitem.item as Column;
                var label = listitem.child as Gtk.Label;
                label.label = item.default_val;
            });
            var col = new Gtk.ColumnViewColumn("Default Value", factory);
            col.set_expand(true);
            view.append_column(col);
        }

        [GtkChild]
        private unowned Gtk.ColumnView view;
    }
}