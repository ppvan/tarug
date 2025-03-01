

namespace Tarug {

        public static void main (string[] args){

            /*
               Forward a local service to remote service.
               TCP Client [--> localhost:port --> SSH server -->] TCP server.
                        [--> (3)...............--> (2).....--> (1) ........]
               TCP server will see the request as if it is from SSH server.
               TCP client will see the localhost:port as the TCP server.
             */
            // Localsocket -> SSH host -> remote host

            // SSH (1) info
            string username = "ppvan";
            string password = "ubuntu";
            string server_ip = "127.0.0.1";
            uint16 server_port = 22;

            string remote_host = "localhost";
            uint16 remote_port = 5432;
            uint16 local_destport = 9000;

            var server = new NetworkAddress(server_ip, server_port);
            var local = new NetworkAddress.loopback(local_destport);
            var remote = new NetworkAddress(remote_host, remote_port);


            var auth = new Auth.password_auth(username, password);
            var session = new Session(server);
            session.authenticate(auth);


            // Connect and auth session

            var tunnel = new SSHTunel(session, local, remote);
            var loop = new MainLoop();

            tunnel.listen();
            loop.run();
        }
}