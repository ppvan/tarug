namespace Tarug {
    const int64 SECOND_TO_MS = 1000;
    const int64 MILISECS_TO_US = 1000;


/** Utils class to convert values. */
    public class ValueConverter {
        public static List<Connection> deserialize_connection (string json_data){
            var parser = new Json.Parser();
            var recent_connections = new List<Connection> ();

            try {
                parser.load_from_data(json_data);
                var root = parser.get_root();
                var conns = root.get_array();

                conns.foreach_element((array, index, node) => {
                    var conn = (Connection) Json.gobject_deserialize(typeof (Connection), node);
                    recent_connections.append(conn);
                });
            } catch (Error err) {
                debug(err.message);
            }

            return((owned) recent_connections);
        }

        public static string serialize_connection (List<Connection> conns){
            var builder = new Json.Builder();
            builder.begin_array();

            foreach (var conn in conns) {
                builder.add_value(Json.gobject_serialize(conn));
            }
            builder.end_array();

            var node = builder.get_root();
            return(Json.to_string(node, true));
        }

        public static T[] list_to_array<T> (List<T> list){
            int len = (int) list.length();
            int i = 0;
            T[] array = new T[len];

            list.foreach((item) => {
                array[i++] = item;
            });

            return(array);
        }
    }
}
