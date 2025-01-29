namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/style-switcher.ui")]
    public class StyleSwitcher : Gtk.Widget {
        [GtkChild] unowned Gtk.CheckButton system_selector;
        [GtkChild] unowned Gtk.CheckButton light_selector;
        [GtkChild] unowned Gtk.CheckButton dark_selector;

        public int style { get; set; }
        public bool show_system { get; set; default = true; }

        static construct {
            set_layout_manager_type(typeof (Gtk.BinLayout));
            set_css_name("themeswitcher");
        }

        construct {
            this.notify["style"].connect(this.on_style_changed);

            var s = autowire<Settings> ();
            s.bind("color-scheme", this, "style", GLib.SettingsBindFlags.DEFAULT);
        }

        private void on_style_changed (){
            this.freeze_notify();
            if (this.style == ApplicationStyle.SYSTEM) {
                this.system_selector.active = true;
                this.light_selector.active = false;
                this.dark_selector.active = false;
            } else if (this.style == ApplicationStyle.LIGHT) {
                this.system_selector.active = false;
                this.light_selector.active = true;
                this.dark_selector.active = false;
            } else {
                this.system_selector.active = false;
                this.light_selector.active = false;
                this.dark_selector.active = true;
            }
            this.thaw_notify();
        }

        [GtkCallback]
        private void theme_check_active_changed (){
            if (this.system_selector.active) {
                if (this.style != ApplicationStyle.SYSTEM) {
                    this.style = ApplicationStyle.SYSTEM;
                }
            } else if (this.light_selector.active) {
                if (this.style != ApplicationStyle.LIGHT) {
                    this.style = ApplicationStyle.LIGHT;
                }
            } else {
                if (this.style != ApplicationStyle.DARK) {
                    this.style = ApplicationStyle.DARK;
                }
            }
        }
    }
}
