namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/view-data-view.ui")]
    public class ViewDataView : Gtk.Box {
        public ViewDataViewModel viewdata_viewmodel { get; set; }

        public ViewDataView(){
            Object();
        }

        construct {
            viewdata_viewmodel = autowire<ViewDataViewModel> ();
        }

        [GtkCallback]
        private async void reload_data (){
            yield viewdata_viewmodel.reload_data ();
        }

        [GtkCallback]
        private async void next_page (){
            yield viewdata_viewmodel.next_page ();
        }

        [GtkCallback]
        private async void pre_page (){
            yield viewdata_viewmodel.pre_page ();
        }
    }
}
