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

        public async Bytes read (){
            print("read channel\n");
            var buf = new uint8[1024];
            size_t bytes_write = SSH2.Error.AGAIN;
            do {
                bytes_write = raw_channel.read(buf);
                if (bytes_write != SSH2.Error.AGAIN)break;
                session.wait_socket(GLib.IOCondition.IN);
            } while (bytes_write == SSH2.Error.AGAIN);

            if (raw_channel.eof() == EOF) {
                return new Bytes(buf).slice(0, 0);
            }

            return new Bytes(buf).slice(0, bytes_write);
        }

        public async void write (Bytes content){
            print("write channel\n");

            size_t wr = 0;
            size_t i = 0;
            size_t len = content.length;

            do {
                uint8[] chunk = content.slice(wr, len - wr).get_data();
                i = raw_channel.write(chunk);
                wr += i;
            } while (i > 0 && wr < len);
        }
    }

    public class Session {

        enum State {
            NONE,
            CONNECTED,
            HANDSHAKED,
            AUTHENTICATED
        }

        public signal void data_available ();

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
                var block_directions = raw_session.block_directions.to_condition ();
                yield wait_socket (block_directions);
            }


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
            var input = new DataInputStream(conn.input_stream);
            var output = new DataOutputStream(conn.output_stream);

            var host = dest.get_hostname();
            var port = dest.get_port();
            var shost = src.get_hostname();
            var sport = src.get_port();

            var channel = yield session.direct_tcpip(host, port, shost, sport);
            var is_new = true;

            while (!conn.is_closed()) {
                var client_msg = yield read_request (input, is_new);
                is_new = false;

                yield channel.write (client_msg);

                var response = yield channel.read ();

                if (response.length == 0) {
                    break;
                }

                yield write_response (output, response);
            }
        }

        private async void write_response (OutputStream stream, Bytes bytes){
            print("write client\n");
            size_t i = 0;
            size_t wr = 0;
            size_t len = bytes.length;

            do {
                var chunk = new Bytes.from_bytes(bytes, wr, len - wr);
                i = yield stream.write_bytes_async (chunk);

                wr += i;
            } while (i > 0 && wr < len);
        }

        private async Bytes read_request (InputStream stream, bool is_new){
            print("read client\n");

            uint32 expected_header_bytes = (is_new ? 4 : 5);
            uint8[] buf = new uint8[expected_header_bytes];
            var bytes_read = yield stream.read_async (buf, Priority.DEFAULT);
            assert (bytes_read == expected_header_bytes);

            uint32 message_len_network = *((uint32*)&buf[(is_new ? 0 : 1)]);
            var message_length = uint32.from_network(message_len_network);
            print("mes len: %lu\n", message_length);

            uint8[] body_buf = new uint8[message_length - expected_header_bytes];

            var content = yield stream.read_async (body_buf, Priority.DEFAULT);

            print("command: %s\n", (string)(body_buf));

            var package_data = new uint8[message_length];
            GLib.Memory.copy (package_data, buf, expected_header_bytes);
            GLib.Memory.copy (&package_data[expected_header_bytes], body_buf, message_length - expected_header_bytes);

            return new Bytes.take (package_data);
        }
    }
}