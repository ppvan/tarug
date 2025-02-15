namespace Tarug {


    public static void test_query_epoll() {
        var loop = new MainLoop();

        // Prepare dependency injecttion container.
        var container = Container.instance();
        var settings = new Settings(Config.APP_ID);
        container.register(settings);

        var sql_service = new SQLService();
        var conn = new Connection("test conn") {
            host = "127.0.0.1",
            port = "5432",
            user = "jay_user",
            password = "jay_password",
            database = "dvdrental"
        };

        sql_service.connect_db.begin(conn, (obj, res) => {
            var text = """SELECT ta.tablename, cls.reltuples::bigint AS estimate FROM pg_tables ta
    JOIN pg_class cls ON cls.relname = ta.tablename 
    WHERE schemaname=$1;""";

            var query = new Query.with_params(text, {"public"});
            sql_service.exec_query_params.begin(query, (obj, res) => {
                var relation = (Relation) sql_service.exec_query_params.end(res);
                sql_service.exec_query.begin(new Query("SELECT NOW()"), (obj, res) => {
                    var relation2 = (Relation) sql_service.exec_query.end(res);
                    printerr(relation.to_string());
                    printerr(relation2.to_string());
                    loop.quit();
                });

            });
        });
        loop.run();
    }



    public static int main(string []args) {
        Test.init(ref args);
        Test.add_func("/sql-service/basic", test_query_epoll);

        return Test.run();
    }
}