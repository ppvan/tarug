namespace Tarug {
    public class SchemaViewModel : BaseViewModel {
        const string DEFAULT = "public";

        public ObservableList<Schema> schemas { get; set; default = new ObservableList<Schema> (); }
        public Schema ? current_schema { get; set; }

        // Needed to interact with gtk.dropdown properly.
        public int current_index { get; set; }

        public SchemaRepository repository;

        // Services

        public SchemaService schema_service { get; private set; }

        public SchemaViewModel(SchemaService service){
            base();
            this.schema_service = service;

            this.notify["current-schema"].connect(() => {
                EventBus.instance().schema_changed(current_schema);
            });

            EventBus.instance().connection_active.connect(() => {
                Timeout.add_once(300, () => {
                    database_connected.begin();
                });
            });

            EventBus.instance().schema_reload.connect(() => {
                this.reload.begin();
            });

            EventBus.instance().connection_disabled.connect(() => {
                this.logout.begin();
            });
        }

        public void select_index (int index){
            if (index < 0 || index >= schemas.size) {
                return;
            }
            debug("Select index %d, %s\n", index, schemas[index].name);
            select_schema.begin(schemas[index]);
        }

        public async void reload () throws tarugError {
            if (current_schema == null) {
                return;
            }
            yield select_schema (current_schema);
        }

        public async void logout () throws tarugError {
            current_schema = null;
            schemas.clear();
        }

        private async void database_connected () throws tarugError {
            // auto load schema list.
            yield load_schemas ();

            yield select_schema (schemas.find(s => s.name == DEFAULT));
        }

        /** Select current schema */
        private async void select_schema (Schema schema) throws tarugError {
            debug("Select schema: %s", schema.name);
            current_schema = schema;
        }

        /** List schema from database. */
        private async void load_schemas () throws tarugError {
            var unload_schemas = yield schema_service.schema_list ();

            var public_first_schemas = new List<Schema> ();

            foreach (var s in unload_schemas) {
                if (s.name == DEFAULT) {
                    public_first_schemas.insert(s, 0);
                } else {
                    public_first_schemas.append(s);
                }
            }

            schemas.clear();
            schemas.append_all(public_first_schemas);
        }
    }
}
