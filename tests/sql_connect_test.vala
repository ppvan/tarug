using Tarug;


void test_connect_db_ok (){

    var main_loop = GLib.MainContext.default();
    var waiter = new AsyncResultWaiter(main_loop);
    var sql_service = new SQLService();
    var conn = new Connection("test conn") {
        host = "127.0.0.1",
        port = "5432",
        user = "postgres",
        password = "postgres",
        database = "dvdrental"
    };


    sql_service.connect_db.begin(conn, waiter.async_completion);

    try {
        sql_service.connect_db.end(waiter.async_result());
        sql_service.close_db ();
    } catch (TarugError err) {
        Test.fail_printf(err.message);
    }
}

void test_connect_db_fail (){
    var main_loop = GLib.MainContext.default();
    var waiter = new AsyncResultWaiter(main_loop);
    var sql_service = new SQLService();
    var conn = new Connection("wrong database config") {
        host = "127.0.0.1",
        port = "5432",
        user = "postgres",
        password = "postgres",
        database = "dogsarethebest"
    };


    sql_service.connect_db.begin(conn, waiter.async_completion);

    try {
        sql_service.connect_db.end(waiter.async_result());
        sql_service.close_db ();
    } catch (TarugError err) {
        assert_error (err, err.domain, TarugError.CONNECTION_ERROR);
    }
}

public int main (string[] args){
    Test.init(ref args);

    var container = Container.instance();
    var settings = new Settings(Config.APP_ID);
    container.register(settings);

    Test.add_func("/database/connect_success", test_connect_db_ok);
    Test.add_func("/database/connect_fail", test_connect_db_fail);


    return Test.run();
}