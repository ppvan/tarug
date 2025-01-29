namespace Tarug {
/** Class process and load {@link Schema} infomation */
    public class SchemaService : Object {
        public const string SCHEMA_LIST_SQL = """
        SELECT schema_name 
        FROM information_schema.schemata
        WHERE schema_name NOT LIKE 'pg_%'
        ;
        """;
        // WHERE schema_name NOT LIKE 'pg_%' AND schema_name NOT LIKE 'information_schema'

        private SQLService sql_service;

        public SchemaService(SQLService service){
            this.sql_service = service;
        }

        /** Get the schema list.
         */
        public async List<Schema> schema_list (){
            var list = new List<Schema> ();
            try {
                var query = new Query(SCHEMA_LIST_SQL);
                var relation = yield sql_service.exec_query (query);

                for (int i = 0; i < relation.rows; i++) {
                    var s = new Schema(relation[i][0]);
                    list.append(s);
                }
            } catch (tarugError err) {
                debug(err.message);
            }

            return(list);
        }
    }
}
