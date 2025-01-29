namespace Tarug {
    public class TableDataViewModel : DataViewModel {
        public const int MAX_FETCHED_ROW = 50;

        public Table ? selected_table { get; set; }

        public TableDataViewModel(SQLService service){
            Object(sql_service : service);

            this.notify["current-page"].connect(() => {
                if (current_page > 0) {
                    has_pre_page = true;
                } else {
                    has_pre_page = false;
                }
            });

            this.notify["current-relation"].connect(() => {
                int offset = MAX_FETCHED_ROW * current_page;
                if (where_query.strip() == "") {
                    row_ranges = @"Page $(current_page + 1) of $(total_pages) ($(1 + offset) - $(offset + current_relation.rows) of $(total_records) records)";
                } else {
                    int count = current_relation.rows;
                    row_ranges = @"Page $(current_page + 1) of $(total_pages) ($(1 + offset) - $(offset + current_relation.rows) of $(count) records)";
                }


                if (current_page + 1 >= total_pages) {
                    has_next_page = false;
                } else {
                    has_next_page = true;
                }
            });


            this.notify["selected-table"].connect(() => {
                current_page = 0;
                this.where_query = "";
                reload_data.begin();
            });

            EventBus.instance().selected_table_changed.connect((table) => {
                selected_table = table;
                this.total_records = table.row_count;
                this.total_pages = (table.row_count + MAX_FETCHED_ROW - 1) / MAX_FETCHED_ROW;
            });
        }

        public async void reload_data (){
            yield load_data (selected_table, current_page);
        }

        public async void next_page (){
            current_page = current_page + 1;
            yield load_data (selected_table, current_page);
        }

        public async void pre_page (){
            current_page = current_page - 1;
            yield load_data (selected_table, current_page);
        }

        private inline async void load_data (Table table, int page){
            try {
                is_loading = true;
                current_relation = yield sql_service.select_where (table, where_query, page, MAX_FETCHED_ROW);

                is_loading = false;
                debug("Rows: %d", current_relation.rows);
            } catch (tarugError err) {
                this.err_msg = err.message;
            }
        }

        public async void update_row (Vec<TableField> fields){
            var table = this.selected_table;
            if (table == null) {
                return;
            }

            //  yield this.sql_service.update_row (table, fields);
        }

        // private inline async void
    }
}
