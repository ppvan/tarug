

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/table-graph.ui")]
    public class TableGraph : Gtk.Box {
        private TableViewModel viewmodel;

        private TableBox current_table;
        private UIContext ctx;


        public TableGraph(){
            Object();
        }

        construct {
            this.viewmodel = autowire<TableViewModel>();

            this.viewmodel.notify["selected-table"].connect(() => {
                var table = this.viewmodel.selected_table;
                this.current_table = new TableBox(table);
                this.ctx = new UIContext();

                area.queue_draw();
            });

            this.ctx = new UIContext();


            this.realize.connect(() => {
                var scrollEvent = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
                scrollEvent.scroll.connect(this.handle_scroll);

                var dragEvent = new Gtk.GestureDrag();
                dragEvent.drag_update.connect(this.drag_update);
                dragEvent.drag_end.connect(this.drag_end);



                area.add_controller(scrollEvent);
                area.add_controller(dragEvent);
                area.set_draw_func(redraw);
            });
        }

        private bool handle_scroll (Gtk.EventControllerScroll event, double dx, double dy){
            Gdk.ModifierType mask = event.get_current_event_state();
            if (mask != Gdk.ModifierType.CONTROL_MASK) {
                return(false);
            }

            if (dy > 0) {
                this.ctx.zoom *= 0.9;
            } else {
                this.ctx.zoom *= 1.1;
            }

            this.area.queue_draw();

            return(true);
        }

        private void drag_end (Gtk.GestureDrag drag, double x, double y){
            this.ctx.last_x += x;
            this.ctx.last_y += y;
            this.ctx.offset_x = 0;
            this.ctx.offset_y = 0;
            area.queue_draw();
        }

        private void drag_update (Gtk.GestureDrag drag, double x, double y){
            drag.get_offset(out x, out y);
            this.ctx.offset_x = x;
            this.ctx.offset_y = y;
            area.queue_draw();
        }

        private void redraw (Gtk.DrawingArea area, Cairo.Context cr, int width, int height){


            cr.translate(width / 2 + ctx.last_x + ctx.offset_x, height / 2 + ctx.last_y + ctx.offset_y);
            cr.scale(ctx.zoom, ctx.zoom);

            cr.set_source_rgb(30 / 255.0, 30 / 255.0, 30 / 255.0);
            cr.paint();

            var text_h = line_height(cr);

            var cur_color = this.get_color();


            var table = this.viewmodel.selected_table;
            var table_width = width * 2 / 5;
            var table_height = (table.columns.length + 1) * (text_h + 2 * TextBox.DEFAULT_PAD);

            this.current_table.boundary = { -(width / 2 - TextBox.DEFAULT_PAD * 8), -table_height / 2, table_width, table_height };
            this.current_table.color = cur_color;

            current_table.update(ctx);
            current_table.draw(cr, width, height);
        }

        private int line_height (Cairo.Context cr){
            var layout = Pango.cairo_create_layout(cr);
            layout.set_font_description(Pango.FontDescription.from_string("Roboto 12"));
            layout.set_text("jjjjjjjjjj", -1); // j is the highest character, good for line height measure.

            int text_w = 0, text_h = 0;
            layout.get_pixel_size(out text_w, out text_h);

            return(text_h);
        }

        [GtkChild]
        private unowned Gtk.DrawingArea area;
    }

    public class UIContext : Object {
        public double mouse_x { get; set; }
        public double mouse_y { get; set; }
        public double offset_x { get; set; default = 0; }
        public double offset_y { get; set; default = 0; }

        public double last_x { get; set; default = 0; }
        public double last_y { get; set; default = 0; }

        public double zoom { get; set; default = 1.0; }

        public UIContext(){}
    }
}
