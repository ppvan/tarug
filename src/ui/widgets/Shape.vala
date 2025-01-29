using Gtk;
using Gdk;
namespace Tarug {
    public interface Shape : Object {
        public abstract void draw (Cairo.Context cr, int width, int height);
    }

    public sealed class TextBox : Object, Shape {
        public static int DEFAULT_PAD = 8;
        public static int DEFAULT_LINE_HEIGHT = 20;

        private string text;
        private Gdk.Rectangle boundary;

        public enum Align {
            CENTER,
            LEFT,
            RIGHT
        }

        public Pango.FontDescription custom_font { get; set; default = Pango.FontDescription.from_string("Roboto 16"); }
        public Gdk.RGBA color { get; set; default = { 0, 0, 0, 1 }; }
        public Gdk.RGBA bg_color { get; set; default = { 0, 0, 0, 0.0f }; }
        public Align text_align { get; set; default = Align.CENTER; }
        public bool show_box { get; set; default = true; }

        public TextBox(string text, Gdk.Rectangle rect){
            base();
            this.text = text;
            this.boundary = rect;
        }

        public void draw (Cairo.Context cr, int width, int height){
            cr.move_to(boundary.x, boundary.y);

            if ((show_box)) {
                cr.save();
                cr.set_source_rgba(bg_color.red, bg_color.green, bg_color.blue, bg_color.alpha);
                cr.rectangle(boundary.x, boundary.y, boundary.width, boundary.height);
                cr.fill();

                cr.restore();
                cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                cr.rectangle(boundary.x, boundary.y, boundary.width, boundary.height);
                cr.stroke();
            }

            int text_w = 0, text_h = 0;

            var layout = Pango.cairo_create_layout(cr);
            layout.set_font_description(custom_font);
            layout.set_text(text, -1);
            layout.get_pixel_size(out text_w, out text_h);
            layout.set_width((boundary.width - 2 * TextBox.DEFAULT_PAD) * Pango.SCALE);
            layout.set_height((boundary.height - 2 * TextBox.DEFAULT_PAD) * Pango.SCALE);
            layout.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
            layout.set_alignment(Pango.Alignment.CENTER);

            cr.move_to(boundary.x + TextBox.DEFAULT_PAD, boundary.y + (boundary.height - text_h) / 2);
            switch (text_align) {
                case Align.CENTER:
                    layout.set_alignment(Pango.Alignment.CENTER);
                    break;

                case Align.LEFT:
                    layout.set_alignment(Pango.Alignment.LEFT);
                    break;

                case Align.RIGHT:
                    layout.set_alignment(Pango.Alignment.RIGHT);
                    break;

                default:
                    assert_not_reached();
            }

            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            Pango.cairo_show_layout(cr, layout);
            cr.stroke();
        }
    }

    public sealed class TableBox : Object, Shape {
        private Table table;


        public Gdk.Rectangle boundary { get; set; default = { 0, 0, 100, 100 }; }
        public Gdk.RGBA color { get; set; default = { 1, 1, 1, 1 }; }


        // Computed from ui-state

        private bool isHover = false;


        public TableBox(Table table){
            this.table = table;

            // this.boundary.height = (table.columns.length + 1) * (TextBox.DEFAULT_LINE_HEIGHT + 2 * TextBox.DEFAULT_PAD);
            // this.boundary.width = 0;
        }

        public void update (UIContext ctx){
            this.isHover = this.boundary.contains_point((int) ctx.mouse_x, (int) ctx.mouse_y);
        }

        public void draw (Cairo.Context cr, int width, int height){
            cr.move_to(boundary.x, boundary.y);

            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.rectangle(boundary.x, boundary.y, boundary.width, boundary.height);
            cr.stroke();

            int row_height = boundary.height / (1 + table.columns.length);
            var header = new TextBox(table.name, { boundary.x, boundary.y, boundary.width, row_height });
            header.custom_font.set_weight(Pango.Weight.BOLD);
            header.bg_color = { 64 / 255f, 64 / 255f, 64 / 255f, 1 };
            header.color = this.color;
            header.draw(cr, width, height);


            int index = 1;
            foreach (var column in table.columns) {
                var col_name = new TextBox(column.name, { boundary.x, boundary.y + index * row_height, boundary.width / 2, row_height });
                col_name.color = this.color;
                col_name.text_align = TextBox.Align.LEFT;

                var col_type = new TextBox(column.column_type, { boundary.x + boundary.width / 2, boundary.y + index * row_height, boundary.width / 2, row_height });
                col_type.color = this.color;
                col_type.text_align = TextBox.Align.RIGHT;

                col_name.draw(cr, width, height);
                col_type.draw(cr, width, height);
                index++;
            }

            int spacing = (height - table.foreign_keys.length * 2 * row_height) / (table.foreign_keys.length + 1);
            int next_y = -(table.foreign_keys.length * row_height + (table.foreign_keys.length - 1) * spacing / 2);
            int next_x = width / 2 - boundary.width / 2 - TextBox.DEFAULT_PAD * 8;
            foreach (var fk in table.foreign_keys) {
                var fk_header = new TextBox(fk.fk_table, { next_x + TextBox.DEFAULT_PAD, next_y, boundary.width / 2, row_height });
                fk_header.custom_font.set_weight(Pango.Weight.BOLD);
                fk_header.bg_color = { 64 / 255f, 64 / 255f, 64 / 255f, 1 };
                fk_header.color = this.color;
                fk_header.draw(cr, width, height);

                string fk_compose = string.joinv(", ", fk.fk_columns);
                var fk_compose_box = new TextBox(fk_compose, { next_x + TextBox.DEFAULT_PAD, next_y + row_height, boundary.width / 2, row_height });
                fk_compose_box.color = this.color;
                fk_compose_box.text_align = TextBox.Align.CENTER;

                fk_compose_box.draw(cr, width, height);

                string col_compose = string.joinv(", ", fk.columns);
                var col_index = table.columns.find((_col) => {
                    return _col.name == col_compose;
                });

                if (col_index != -1) {
                    var arrow = new Arrow({ boundary.x + boundary.width, boundary.y + (col_index + 1) * row_height + row_height / 2 }, { next_x + TextBox.DEFAULT_PAD, next_y + row_height });
                    arrow.draw(cr, width, height);
                } else {
                    // TODO: handle compose foreign key case (2 or more column in 1 fk)
                }

                next_y += 2 * row_height + spacing;
            }
        }
    }

    public struct Vec2D {
        double x;
        double y;

        public Vec2D add (Vec2D other){
            return({ this.x + other.x, this.y + other.y });
        }

        public Vec2D substract (Vec2D other){
            return({ this.x - other.x, this.y - other.y });
        }

        public Vec2D orthogonal (){
            return({ -this.y, this.x });
        }

        public Vec2D divide (double d){
            return({ this.x / d, this.y / d });
        }

        public Vec2D normalize (){
            var length = GLib.Math.hypot(this.x, this.y);
            return({ this.x / length, this.y / length });
        }

        public string to_str (){
            return("(%.2f, %.2f)".printf(x, y));
        }
    }

    public class Arrow : Object, Shape {
        private Vec2D tail;
        private Vec2D head;


        public Arrow(Vec2D tail, Vec2D head){
            this.tail = tail;
            this.head = head;
        }

        public void draw (Cairo.Context cr, int width, int height){
            var orthogonal = tail.substract(head).orthogonal().normalize();
            var mid = tail.add(head).divide(2);
            var p2 = mid.add(orthogonal.divide(1 / 64.0));
            var p1 = mid.substract(orthogonal.divide(1 / 64.0));

            cr.move_to(tail.x, tail.y);

            if (tail.y < head.y) {
                cr.curve_to(p2.x, p2.y, p1.x, p1.y, head.x, head.y);
            } else {
                cr.curve_to(p1.x, p1.y, p2.x, p2.y, head.x, head.y);
            }

            cr.stroke();
        }
    }


    public sealed class CairoIcon : Object, Shape {
        private string filepath;

        public CairoIcon(string iconname){
        }

        public void draw (Cairo.Context cr, int width, int height){
            // Cairo.SvgSurface surface = new Cairo.SvgSurface(this.filepath, 48, 48);
            // cr.set_source_surface(surface, 0, 0);
        }
    }
}
