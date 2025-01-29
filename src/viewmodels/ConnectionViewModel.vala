namespace Tarug {
    public class ConnectionViewModel : BaseViewModel {
        public enum State {
            IDLE,
            CONNECTING,
            ERROR
        }


        uint timeout_id = 0;
        public ConnectionRepository repository { get; private set; }
        public SQLService sql_service { get; private set; }
        public NavigationService navigation_service { get; private set; }



        // States

        public State current_state { get; private set; default = State.IDLE; }
        public string err_msg { get; private set; default = "hello world"; }
        public ObservableList<Connection> connections { get; private set; default = new ObservableList<Connection> (); }
        public Connection ? selected_connection { get; set; }

        /** True when trying to establish a connection util know results. */
        public bool is_connectting { get; set; default = false; }

        public ConnectionViewModel(ConnectionRepository repository, SQLService sql_service, NavigationService navigation_service){
            base();
            this.repository = repository;
            this.sql_service = sql_service;
            this.navigation_service = navigation_service;

            var loaded_conn = repository.find_all();
            connections.extend(loaded_conn);

            if (connections.empty()) {
                // new_connection();
            }

            this.bind_property("current-state", this, "is-connectting", SYNC_CREATE, from_state_to_connecting);

            // Auto save data each 10 secs in case app crash.
            // Timeout.add_seconds (10, () => {
            // repository.save (connections.to_list ());
            // return Source.CONTINUE;
            // }, Priority.LOW);
        }

        public void new_connection (){
            var conn = new Connection();
            conn = repository.append_connection(conn);
            connections.append(conn);
            selected_connection = conn;

            // save_connections ();
        }

        public void dupplicate_connection (Connection conn){
            var clone = conn.clone();
            clone.name = clone.name + " (copy)";
            clone.id = 0;
            repository.append_connection(clone);
            connections.insert(connections.indexof(conn) + 1, clone);
            selected_connection = clone;
        }

        public void remove_connection (Connection conn){


            uint target = connections.indexof(conn);
            uint nearest = target < connections.size - 1 ? target + 1 : target - 1;
            if (0 <= nearest && nearest < connections.size) {
                selected_connection = connections[(int) nearest];
            } else {
                selected_connection = null;
            }


            repository.remove_connection(conn);
            connections.remove(conn);
        }

        public void import_connections (List<Connection> connections){
            repository.append_all(connections);

            this.connections.append_all(connections);
        }

        public async void active_connection (Connection connection){
            this.current_state = State.CONNECTING;
            try {
                yield sql_service.connect_db (connection);

                EventBus.instance().connection_active(connection);
            } catch (tarugError err) {
                this.err_msg = err.message.dup();
                debug("Error: %s", err.message);
                this.current_state = State.ERROR;
                return;
            }
            this.current_state = State.IDLE;
        }

        public List<Connection> export_connections (){
            return(repository.find_all());
        }

        public void save_connections (){
            if (timeout_id != 0) {
                Source.remove(timeout_id);
            }

            timeout_id = Timeout.add(200, () => {
                timeout_id = 0;
                repository.save(connections.to_list());
                return(Source.REMOVE);
            });
        }

        private bool from_state_to_connecting (Binding binding, Value from, ref Value to){
            ConnectionViewModel.State state = (ConnectionViewModel.State) from.get_enum();
            if (state == ConnectionViewModel.State.CONNECTING) {
                to.set_boolean(true);
            } else {
                to.set_boolean(false);
            }

            return(true);
        }
    }
}
