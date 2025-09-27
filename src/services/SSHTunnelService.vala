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

            // Use postgresql specific protocol to read exact len (like HTTP Content-Length headers).
            // Not great, but I'm not sure how to make it work  otherwise
            // https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS
            ssize_t len = SSHTunel.network_bytes_to_uint32(&header[1]);

            var buf = new uint8[len - 4];
            raw_channel.read(buf);

            var total = SSHTunel.concat_bytes(header, buf);
            return new Bytes.take(total);
        }

        public bool eof (){
            return raw_channel.eof() == EOF;
        }

        public void write (Bytes content){
            ssize_t wr = 0;
            ssize_t i = 0;
            ssize_t len = content.length;

            do {
                uint8[] chunk = content.slice(wr, len - wr).get_data();
                i = raw_channel.write(chunk);
                wr += i;
            } while (i > 0 && wr < len);
        }

        public void close (){
            raw_channel.close();
            raw_channel.wait_closed();
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

        public void connect () throws Error {
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

        public void authenticate (Auth auth) throws Error {
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
                conn.socket.condition_wait(IOCondition.IN);
            }
            raw_session.blocking = false;

            return new Channel(this, (owned) raw_channel);
        }

        public async void wait_socket (IOCondition condition){
            var socket = conn.get_socket();
            var source = socket.create_source(condition, null);
            source.set_callback(() => {
                wait_socket.callback();
                return false;
            });
            source.attach();
            yield;
        }

        public bool is_readable (){
            var socket = conn.get_socket();
            return socket.condition_check(IOCondition.IN) == IOCondition.IN;
        }

        public string get_error_message (){
            char[] msg = null;
            raw_session.get_last_error(out msg);
            var builder = new StringBuilder.from_buffer(msg);

            return builder.free_and_steal();
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


        public SSHTunel(Session session, NetworkAddress dest){
            error_type = Quark.from_string("ssh-tunnel-error");
            this.session = session;
            this.dest = dest;
        }

        ~SSHTunel(){}

        public override bool incoming (GLib.SocketConnection connection, GLib.Object ? source_object){
            process_incoming.begin(connection);
            return true;
        }

        // Open a tunnel on an available port, return the port if success, 0 on error
        public uint16 open_tunnel (){
            try {
                this.stop();
                uint16 local_port = this.add_any_inet_port(null);
                this.src = new NetworkAddress.loopback(local_port);
                this.start();

                return local_port;
            } catch (Error err) {
                debug("error open tunnel: %s", err.message);
                return 0;
            }
        }

        // Create the tunnel when a new connection is accepted
        private async void process_incoming (SocketConnection conn){
            debug("Accept connection");
            var input = new DataInputStream(conn.input_stream);
            var output = new DataOutputStream(conn.output_stream);
            var socket = conn.get_socket();
            var channel = yield create_ssh_chanel ();

            while (!conn.is_closed()) {
                try {
                    // Wait until we have data in the (local) socket
                    yield wait_local_socket (socket, IOCondition.IN);

                    var client_msg = yield read_local_socket (input);

                    if (client_msg.length == 0) {
                        debug("client say not thing, assume closed\n");
                        break;
                    }

                    // If we have some data, write it to the SSH connection
                    channel.write(client_msg);
                    // Now we wait for server response some data in the SSH connection
                    yield session.wait_socket (IOCondition.IN);

                    // Read data from SSH connection until done
                    while (true) {
                        var response = channel.read();
                        if (response.length == 0) {
                            break;
                        }
                        write_message(output, response);
                        if (channel.eof()) {
                            debug("Server say nothing, left\n");
                            conn.close();
                        }
                    }
                } catch (Error err) {
                    debug("broken pipe: %s", err.message);
                }
            }
        }

        private void write_message (OutputStream stream, Bytes bytes) throws Error {
            ssize_t i = 0;
            ssize_t wr = 0;
            ssize_t len = bytes.length;
            do {
                var chunk = new Bytes.from_bytes(bytes, wr, len - wr);
                i = stream.write_bytes(chunk);
                wr += i;
            } while (i > 0 && wr < len);
        }

        private async Bytes read_local_socket (InputStream input) throws Error {
            uint8[] body_buffer = new uint8[16 * 1024];
            ssize_t read_bytes = yield input.read_async (body_buffer, Priority.DEFAULT);

            return new Bytes.take(body_buffer).slice(0, read_bytes);
        }

        private async Channel create_ssh_chanel (){
            var host = dest.get_hostname();
            var port = dest.get_port();
            var shost = src.get_hostname();
            var sport = src.get_port();

            var channel = yield session.direct_tcpip (host, port, shost, sport);

            return channel;
        }

        public static uint32 network_bytes_to_uint32 (uint8 * raw_bytes){
            uint32 network_val = *((uint32 *) raw_bytes);
            return uint32.from_network(network_val);
        }

        public static uint8[] concat_bytes (uint8[] first, uint8[] second){
            uint8[] total = new uint8[first.length + second.length];

            GLib.Memory.copy(total, first, first.length);
            GLib.Memory.copy(&total[first.length], second, second.length);

            return total;
        }

        public static async void wait_local_socket (Socket socket, IOCondition condition){
            var source = socket.create_source(condition, null);
            source.set_callback(() => {
                wait_local_socket.callback();
                return false;
            });
            source.attach();
            yield;
        }
    }
}
