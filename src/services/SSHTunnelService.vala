namespace Tarug {

    public class Auth {

        public enum AuthMethod {
            NONE,
            PASSWORD,
            PUBLIC_KEY
        }

        public AuthMethod auth_method { get; private set; }
        public string username { get; private set; }
        public string password { get; private set; }

        public Auth.password_auth(string username, string password){
            this.username = username;
            this.password = password;
            this.auth_method = Auth.AuthMethod.PASSWORD;
        }

        public Auth.public_key_auth(){}
    }

    public class Channel {

        private SSH2.Channel raw_channel;
        private Session session;

        private const int EOF = 1;



        public Channel(Session session, owned SSH2.Channel chan){
            this.session = session;
            this.raw_channel = (owned) chan;
        }

        ~Channel(){
            this.raw_channel.close();
        }

        public Bytes read (){
            var header = new uint8[5];
            ssize_t expected_len = raw_channel.read(header);
            if (expected_len == SSH2.Error.AGAIN) {
                return new Bytes(null);
            }

            ssize_t len = SSHTunel.network_bytes_to_uint32 (&header[1]);

            var buf = new uint8[len - 4];
            raw_channel.read(buf);

            var total = SSHTunel.concat_bytes (header, buf);
            return new Bytes.take (total);
        }

        public bool eof() {
            return raw_channel.eof() == EOF;
        }

        public void write (Bytes content){
            print("write channel\n");

            ssize_t wr = 0;
            ssize_t i = 0;
            ssize_t len = content.length;

            do {
                uint8[] chunk = content.slice(wr, len - wr).get_data();
                i = raw_channel.write(chunk);
                wr += i;
            } while (i > 0 && wr < len);
            print("end write\n"); 
        }

        public void close() {
            raw_channel.close ();
            raw_channel.wait_closed ();
        }
    }

    public class Session {

        enum State {
            NONE,
            CONNECTED,
            HANDSHAKED,
            AUTHENTICATED
        }


        private SSH2.Session<bool> raw_session;
        private SocketConnectable ssh_server;
        private SocketConnection conn;
        private State state;

        public Session(SocketConnectable ssh_server){
            SSH2.init(SSH2.InitFlags.NONE);
            this.raw_session = SSH2.Session.create<bool>();
            this.ssh_server = ssh_server;
            this.state = State.NONE;
        }

        ~Session(){
            SSH2.exit();
        }

        public void connect (){
            var client = new SocketClient();
            conn = client.connect(ssh_server);
            state = State.CONNECTED;
        }

        public void handshake (){
            var fd = conn.get_socket().get_fd();
            var rc = raw_session.handshake(fd);
            if (rc != SSH2.Error.NONE) {
                // throw new Error(error_type, 1, "Can't init handshake");
            }
            state = State.HANDSHAKED;
        }

        public void authenticate (Auth auth){
            connect();
            handshake();
            do_authenticate(auth);
        }

        private void do_authenticate (Auth auth){
            switch (auth.auth_method) {
                case Auth.AuthMethod.NONE:
                    break;
                case Auth.AuthMethod.PASSWORD:
                    auth_password(auth.username, auth.password);
                    break;
                case Auth.AuthMethod.PUBLIC_KEY:
                    assert_not_reached();
            }
        }

        private void auth_password (string username, string password){
            SSH2.Error err = raw_session.auth_password(username, password);
            if (err != SSH2.Error.NONE) {
                // throw error
            }
        }

        public async Channel direct_tcpip (string host, int port, string shost, int sport){
            var raw_channel = raw_session.direct_tcpip(host, port, shost, sport);
            while (raw_session.last_error == SSH2.Error.AGAIN) {
                raw_channel = raw_session.direct_tcpip(host, port, shost, sport);
                if (raw_channel != null) {
                    debug("Connected to chanel");
                    break;
                }
                conn.socket.condition_wait (IOCondition.IN);
            }
            raw_session.blocking = false;

            return new Channel(this, (owned) raw_channel);
        }

        public async void wait_socket(IOCondition condition) {
            var socket = conn.get_socket();
            var source = socket.create_source(condition, null);
            source.set_callback(() => {
                wait_socket.callback();
                return false;
            });
            source.attach();
            yield;
        }

        public bool is_readable() {
            var socket = conn.get_socket();
            return socket.condition_check (IOCondition.IN) == IOCondition.IN;
        }

        public string get_error_message() {
            char[] msg = null;
            SSH2.Error err = raw_session.get_last_error (out msg);

            for (int i = 0; i < msg.length; i++) {
                debug("%c", msg[i]);
            }

            return "";
        }
    }

    public class SSHTunel : SocketService {
        enum SocketState {
            READ,
            WRITE,
            PENDING
        }

        private Session session;
        private NetworkAddress src;
        private NetworkAddress dest;
        private Quark error_type;


        public SSHTunel(Session session, NetworkAddress src, NetworkAddress dest){
            error_type = Quark.from_string("ssh-tunnel-error");
            this.session = session;
            this.src = src;
            this.dest = dest;
        }

        ~SSHTunel(){}

        public override bool incoming (GLib.SocketConnection connection, GLib.Object ? source_object){
            process_incoming.begin(connection);
            return true;
        }

        public void listen (){
            this.stop();
            this.add_inet_port(9000, null);
            this.start();
        }

        private async void process_incoming (SocketConnection conn){
            debug("Accept connection");
            var input = new DataInputStream(conn.input_stream);
            var output = new DataOutputStream(conn.output_stream);

            var host = dest.get_hostname();
            var port = dest.get_port();
            var shost = src.get_hostname();
            var sport = src.get_port();

            var channel = yield session.direct_tcpip(host, port, shost, sport);
            var is_new = true;
            var socket = conn.get_socket ();

            while (!conn.is_closed()) {
                debug("Begin conversation");
                try {
                    debug ("socket 1: %s", socket.condition_check (IOCondition.IN).to_string());
                    yield wait_socket_2(socket, IOCondition.IN);
                    debug ("socket 2: %s", socket.condition_check (IOCondition.IN).to_string());
                    var client_msg = yield dump_read (input);
                    debug ("socket 3: %s", socket.condition_check (IOCondition.IN).to_string());

                    is_new = false;
                    if (client_msg.length == 0) {
                        debug ("Client disconected\n");
                        break;
                    }
                    channel.write (client_msg);

                    yield session.wait_socket (IOCondition.IN);
                    debug ("done");
                    while (true) {
                        debug ("in while");
                        debug ("read chan");
                        var response = channel.read ();
                        debug ("donen 1");
                        if (response.length == 0) {
                            debug("Server say nothing, left\n");
                            break;
                        }
                        debug ("write client");
                        write_message (output, response);
                        debug ("write message done");
                        if (channel.eof()) {
                            yield conn.close_async (Priority.DEFAULT);
                        }
                    }

                } catch (Error err) {
                    debug("Broken pipe");
                    debug ("error: %s", err.message);
                    conn.close();
                }
            }

            debug("closed connection");
        }

        private void write_message (OutputStream stream, Bytes bytes) throws Error {
            ssize_t i = 0;
            ssize_t wr = 0;
            ssize_t len = bytes.length;

            do {
                var chunk = new Bytes.from_bytes(bytes, wr, len - wr);
                debug("begin write %lld", chunk.length);
                i = stream.write_bytes (chunk);
                debug("end write");
                debug ("i = %lld", i);
                wr += i;
            } while (i > 0 && wr < len);
            debug ("end");
        }

        private async Bytes dump_read(InputStream input) {
            uint8[] body_buffer = new uint8[16 * 1024];
            ssize_t read_bytes = yield input.read_async (body_buffer, Priority.DEFAULT);
            debug("Got %lld bytes", read_bytes);

            for (int i = 0; i < read_bytes; i++) {
                print("%c", body_buffer[i]);
            }
            print("\n");


            return new Bytes.take (body_buffer).slice(0, read_bytes);
        }

        private async Bytes read_message(InputStream input, bool is_first = false) throws Error {

            debug("Reading message header: ");
            uint32 header_length = (is_first ? 4 : 5);
            uint8[] header_buffer = new uint8[header_length];
            ssize_t actual = yield input.read_async (header_buffer, Priority.DEFAULT);

            debug("Read %lld as expected %lld", actual, header_length);
            if (actual <= 0) {
                return new Bytes(null);
            }

            int offset = is_first ? 0 : 1;
            uint32 message_length = network_bytes_to_uint32 (&header_buffer[offset]);
            if (message_length <= 4) {
                return new Bytes(null);
            }

            debug("Got message length: %lld, readding body", message_length);

            uint8[] body_buffer = new uint8[message_length - 4];
            ssize_t read_bytes = yield input.read_async (body_buffer, Priority.DEFAULT);
            debug("Got %lld bytes", read_bytes);

            for (int i = 0; i < read_bytes; i++) {
                print("%c", body_buffer[i]);
            }
            print("\n");

            uint8[] package_data = concat_bytes (header_buffer, body_buffer);

            return new Bytes.take (package_data);
        }

        public static uint32 network_bytes_to_uint32(uint8* raw_bytes) {
            uint32 network_val = *((uint32*)raw_bytes);
            return uint32.from_network(network_val);
        }

        public static uint8[] concat_bytes(uint8[] first, uint8[] second) {
            uint8[] total = new uint8[first.length + second.length];

            GLib.Memory.copy (total, first, first.length);
            GLib.Memory.copy (&total[first.length], second, second.length);

            return total;
        }

        public static async void wait_socket_2(Socket socket, IOCondition condition) {
            var source = socket.create_source(condition, null);
            source.set_callback(() => {
                wait_socket_2.callback();
                return false;
            });
            source.attach();
            yield;
        }
    }
}