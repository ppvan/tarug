namespace Psequel {
/**
 * Util class to mesure execution time than log it using debug()
 */
    public class TimePerf {
        private static int64 _start;
        private static int64 _end;

        public static void begin (){
            _start = GLib.get_real_time();
        }

        public static void end (){
            _end = GLib.get_real_time();

            debug(@"Elapsed: %$(int64.FORMAT) ms", (_end - _start) / 1000);
        }

        public static int64 uend (){
            _end = GLib.get_real_time();

            debug(@"Elapsed: %$(int64.FORMAT) μs", (_end - _start));

            return(_end - _start);
        }
    }

    public delegate void Job ();

    public class Worker {
        public string thread_name { private set; get; }
        public Job task;

        public Worker(string name, owned Job task){
            this.thread_name = name;
            this.task = (owned) task;
        }

        public void run (){
            // Thread.usleep ((ulong)1e6);
            this.task();
        }
    }

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

    public class Vec<T>: Object {
        static int DEFAULT_CAPACITY = 64;

        private T[] data;
        private int size;
        private int capacity;

        public int length { get {
                                return this.size;
                            } }
        public delegate bool Predicate<T> (T item);

        public delegate U MapFunc<U, T> (T item);

        public Vec(){
            this.with_capacity(DEFAULT_CAPACITY);
        }

        public Vec.with_data(owned T[] data){
            this.data = data;
            this.size = data.length;
            this.capacity = data.length;
        }

        public Vec.with_capacity(int capacity){
            this.data = new T[capacity];
            this.capacity = capacity;
            this.size = 0;
        }

        public void append (owned T item){
            if (size >= capacity) {
                capacity *= 2;
                data.resize(capacity);
            }


            this.data[size++] = item;
        }

        public int index (T item){
            for (int i = 0; i < this.size; i++) {
                if (item == this.data[i]) {
                    return(i);
                }
            }

            return(-1);
        }

        public int find (Predicate<T> pred){
            for (int i = 0; i < this.size; i++) {
                if (pred(this.data[i])) {
                    return(i);
                }
            }

            return(-1);
        }

        public Vec<T> filter (Predicate<T> pred){
            var vec = new Vec<T>.with_capacity (this.size);

            for (int i = 0; i < this.size; i++) {
                if (pred(this.data[i])) {
                    vec.append(this.data[i]);
                }
            }

            return vec;
        }

        public T pop (){
            if (size <= capacity / 4) {
                capacity /= 2;
                data.resize(capacity);
            }

            return(this.data[--size]);
        }

        public Iterator<T> iterator (){
            return new Iterator<T> (this);
        }

        public List<T> as_list (){
            var list = new List<T>();
            for (int i = 0; i < this.size; i++) {
                list.append(this.data[i]);
            }

            return list;
        }

        public T[] as_array (){
            var dup = new T[this.size];
            for (int i = 0; i < this.size; i++) {
                dup[i] = this.data[i];
            }

            return (owned) dup;
        }

        public Vec<U> map<U> (MapFunc<U, T> func){
            var vec = new Vec<U>.with_capacity (this.capacity);

            foreach (var item in this) {
                vec.append(func(item));
            }

            return vec;
        }

        public new T @get (int index){
            bound_check(index);

            return(this.data[index]);
        }

        public new void set (int index, owned T item){
            bound_check(index);

            this.data[index] = item;
        }

        public new Vec<T> slice (int begin, int end){
            bound_check(begin);
            bound_check(end - 1);

            return(new Vec<T>.with_data(this.data[begin: end]));
        }

        public bool contains (T item){
            bool flag = false;

            for (int i = 0; i < size; i++) {
                if (data[i] == item) {
                    flag = true;
                    break;
                }
            }

            return(flag);
        }

        public class Iterator<T> {
            private int index;
            private Vec<T> vec;

            public Iterator(Vec vec){
                this.vec = vec;
                this.index = 0;
            }

            public bool next (){
                return(index < vec.size);
            }

            public T get (){
                return(this.vec[this.index++]);
            }
        }

        private inline void bound_check (int index){
            if (index < 0 || index >= size) {
                error("Array index out of bound (index = %d, size = %d)", index, size);
            }
        }
    }
}
