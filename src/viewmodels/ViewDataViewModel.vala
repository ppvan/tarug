namespace Tarug {
    public class ViewDataViewModel : DataViewModel {
        public View ? selected_view { get; set; }
        // public View? current_view {get; set;}


        public ViewDataViewModel(SQLService service){
            base();
            this.sql_service = service;

            this.notify["selected-view"].connect(() => {
                current_page = 0;
                reload_data.begin();
            });

            this.notify["current-page"].connect(() => {
                if (current_page > 0) {
                    has_pre_page = true;
                } else {
                    has_pre_page = false;
                }
            });

            this.notify["current-relation"].connect(() => {
                int offset = TableDataViewModel.MAX_FETCHED_ROW * current_page;
                row_ranges = @"Rows $(1 + offset) - $(offset + current_relation.rows)";


                if (current_page + 1 >= total_pages) {
                    has_next_page = false;
                } else {
                    has_next_page = true;
                }
            });

            EventBus.instance().selected_view_changed.connect((view) => {
                selected_view = view;
            });
        }

        public async void reload_data (){
            yield load_data (selected_view, current_page);
        }

        public async void next_page (){
            current_page = current_page + 1;
            yield load_data (selected_view, current_page);
        }

        public async void pre_page (){
            current_page = current_page - 1;
            yield load_data (selected_view, current_page);
        }

        [GtkCallback]
        public async void filter_query (Gtk.Button btn){

            debug("Hey");
        }

        private inline async void load_data (View view, int page){
            try {
                is_loading = true;
                current_relation = yield sql_service.select (view, page, TableDataViewModel.MAX_FETCHED_ROW);

                is_loading = false;
                debug("Rows: %d", current_relation.rows);
            } catch (TarugError err) {
                this.err_msg = err.message;
            }
        }
    }
}
