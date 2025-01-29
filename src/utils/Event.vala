namespace Tarug {
    public class EventBus : Object {
        public signal void schema_changed (Schema schema);
        public signal void connection_active (Connection connection);
        public signal void connection_disabled ();
        public signal void selected_table_changed (Table table);
        public signal void selected_view_changed (View view);
        public signal void schema_reload ();

        private static Vec<EventBus> protypes { get; private set; }

        static construct {
            EventBus._protypes = new Vec<EventBus> ();
        }

        private static EventBus _instance;
        public static EventBus instance (){
            if (EventBus._instance == null) {
                _instance = new EventBus();
            }

            return(_instance);
        }

        public static void clone (){
            if (_instance != null) {
                _protypes.append(_instance);
            }

            _instance = new EventBus();
        }

        private EventBus(){}
    }
}
