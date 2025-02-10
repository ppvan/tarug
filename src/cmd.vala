namespace Tarug {


    public static void test_query_epoll() {
        ThreadPool<Worker> background = null;
        var loop = new MainLoop();

        // Prepare dependency injecttion container.
        var container = Container.instance();
        var settings = new Settings(Config.APP_ID);
        container.register(settings);

        try {
            // Don't change the max_thread because libpq did not support many query with 1 connection.
            background = new ThreadPool<Worker>.with_owned_data ((worker) => {
                worker.run();
            }, 1, false);
        } catch (ThreadError err) {
            debug(err.message);
            assert_not_reached();
        }

        var sql_service = new SQLService(background);
        var conn = new Connection("test conn") {
            host = "127.0.0.1",
            port = "5432",
            user = "jay_user",
            password = "jay_password",
            database = "jay_db"
        };

        sql_service.connect_db.begin(conn, (obj, res) => {

            var query = new Query("SELECT 1;");
            sql_service.exec_query.begin(query, (obj, res) => {
                var relation = (Relation) sql_service.exec_query.end(res);

                printerr(relation.to_string());
                loop.quit();
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