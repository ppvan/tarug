namespace Tarug {
    public class QueryViewModel : BaseViewModel {
        public QueryHistoryViewModel query_history_viewmodel { get; set; }

        public ObservableList<Query> queries { get; set; }
        public Query ? selected_query { get; set; }

        public enum State {
            IDLE,
            EXEC,
            ERROR
        }


        public Schema ? current_schema { get; construct; }
        public SQLService sql_service { get; construct; }
        public State state { get; set; }

        public QueryViewModel(QueryHistoryViewModel query_history_viewmodel){
            Object(query_history_viewmodel : query_history_viewmodel);
        }

        public async void run_selected_query () requires(this.state == State.IDLE) ensures(this.state == State.IDLE || this.state == State.ERROR){
            if (selected_query == null || selected_query.sql == "") {
                return;
            }
            this.state = State.EXEC;
            yield query_history_viewmodel.exec_query (selected_query);

            this.state = State.IDLE;
        }

        public async void run_query (Query query){
            this.state = State.EXEC;
            yield query_history_viewmodel.exec_query (query);

            this.state = State.IDLE;
        }

        public void selected_query_changed (string text){
            Query query = new Query(text);
            selected_query = query;
        }
    }
}
