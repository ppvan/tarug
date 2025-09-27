namespace Tarug {
    public T autowire<T> (){
        var container = Container.instance();
        return((T) container.find_type(typeof (T)));
    }

    public string[] parse_array_result (string array_str){
        int len = array_str.length - 2;
        string content = array_str.substring(1, len);
        return(Csv.parse_row(content));
    }

    public string time_local (string format = "%F-%H:%M"){
        var now = new GLib.DateTime.now();
        var local_time = now.format(format);

        return local_time;
    }

    public bool is_sql_query(string input) {
        var result = PgQuery.parse(input);
        return result.error == null;
    }
}
