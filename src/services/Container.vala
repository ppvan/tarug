namespace Tarug {
    public class Container : Object {
        private HashTable<GLib.Type, Object> dependencies;
        private static Container ? _instance;


        private static Vec<Container> protypes { get; private set; }

        static construct {
            Container._protypes = new Vec<Container>();
        }

        public static Container instance (){
            if (_instance == null) {
                _instance = new Container();
            }

            return(_instance);
        }

        public static void clone (){
            if (_instance != null) {
                Container._protypes.append(_instance);
            }
            _instance = new Container();
        }

        /** Manual dependency injection map */
        private Container(){
            Object();
            dependencies = new HashTable<GLib.Type, Object> (direct_hash, direct_equal);
        }

        public void register (Object obj){
            if (!dependencies.contains(obj.get_type())) {
                dependencies.replace(obj.get_type(), obj);
            } else {
                warning("Register type is already in the map");
            }
        }

        public Object find_type (GLib.Type type){
            if (!dependencies.contains(type)) {
                warning("Type %s not found in the map", type.name());
                assert_not_reached();
            }

            return(dependencies.lookup(type));
        }
    }
}
