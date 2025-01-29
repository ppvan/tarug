namespace Tarug {
    public class QueryHistoryViewModel : BaseViewModel {
        const string AUTO_EXEC_HISTORY = "auto-exec-history";


        public ObservableList<Query> query_history { get; set; default = new ObservableList<Query> (); }
        public Query ? selected_query { get; set; }

        // SQL related result.
        public bool is_loading { get; private set; }
        public bool success { get; private set; }
        public string err_msg { get; private set; }

        public Relation current_relation { get; private set; }
        public Relation.Row ? selected_row { get; set; }

        // Status properties
        public string row_affected { get; private set; }
        public string query_time { get; private set; }

        public SQLService sql_service { get; construct; }
        public QueryRepository query_repository { get; construct; }
        private Settings settings;


        public QueryHistoryViewModel(SQLService sql_service, QueryRepository query_repository){
            Object(sql_service : sql_service, query_repository : query_repository);

            this.settings = autowire<Settings>();
            this.query_history.append_all(query_repository.get_queries());
            this.notify["current-relation"].connect(() => {
                success = true;
                row_affected = @"$(current_relation.row_affected) row affected.";

                if (current_relation.fetch_time / SECOND_TO_MS > 0) {
                    if (current_relation.fetch_time / SECOND_TO_MS / MILISECS_TO_US > 0) {
                        query_time = @"$(current_relation.fetch_time / SECOND_TO_MS / MILISECS_TO_US) s";
                    } else {
                        query_time = @"$(current_relation.fetch_time / SECOND_TO_MS) ms";
                    }
                } else {
                    query_time = @"$(current_relation.fetch_time) μs";
                }
            });
        }

        public async void exec_query (Query query){
            yield run_query_internal (query);

            query_history.prepend(query);
            query_repository.append_query(query);
            selected_query = query;
        }

        public async void exec_history (Query query){
            if (!settings.get_boolean("auto-exec-history")) {
                return;
            }

            debug("setting: %s", settings.get_boolean("auto-exec-history") ? "true" : "false");

            yield run_query_internal (query);

            query_history.remove(query);
            query_history.prepend(query);
            selected_query = query;
        }

        public async void clear_history (){
            query_history.clear();
            query_repository.clear();
        }

        private inline async bool run_query_internal (Query query){
            is_loading = true;

            try {
                current_relation = yield sql_service.exec_query (query);

                is_loading = false;

                return(true);
            } catch (tarugError err) {
                this.err_msg = err.message;
            }

            is_loading = false;
            return(false);
        }
    }
}
