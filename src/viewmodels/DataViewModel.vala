namespace Tarug {
    public class DataViewModel : BaseViewModel {
        public bool has_pre_page { get; set; }
        public bool has_next_page { get; set; }
        public int current_page { get; set; }

        public string row_ranges { get; set; default = ""; }

        public bool is_loading { get; set; }
        public string err_msg { get; set; }
        public string where_query { get; set; default = ""; }

        public Relation current_relation { get; set; }
        public Relation.Row ? selected_row { get; set; }

        public int64 total_records { get; set; }
        public int64 total_pages { get; set; }

        public SQLService sql_service { get; set; }
    }
}
