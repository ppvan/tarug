/* window.vala
 *
 * Copyright 2023 Unknown
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Tarug {
/**
 * Connection info. Have basic infomation to establish a connection to server.
 */
    public class Connection : Object, Json.Serializable {
        public const string DEFAULT = "";
        public const string SCHEME = "postgresql";

        public int64 id { get; set; default = 0; }
        public string name { get; set; default = DEFAULT; }
        public string host { get; set; default = "localhost"; }
        public string port { get; set; default = "5432"; }
        public string user { get; set; default = "postgres"; }
        public string password { get; set; default = "postgres"; }
        public string database { get; set; default = "postgres"; }
        public bool use_ssl { get; set; default = false; }

        public string options { get; set; default = DEFAULT; }

        public string cert_path { get; set; default = ""; }

        public Connection(string name = "New Connection"){
            this._name = name;
        }

        /**
         * build the postgres url from properties.
         *
         * Format = postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
         */
        public string url_form (){
            // postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]

            var parsed_port = 5432;
            if (!int.try_parse(port, out parsed_port, null, 10)) {
                debug("Parse port error: defautl to 5432");
            }


            var safe_user = user != DEFAULT ? user : "postgres";
            var safe_password = password != DEFAULT ? password : "postgres";
            var safe_host = host != DEFAULT ? host : "localhost"; // TODO IPv6 check
            var safe_port = port != DEFAULT ? parsed_port : 5432;
            var safe_db = database != DEFAULT ? @"/$database" : "/postgres";

            var safe_options = use_ssl ? "sslmode=required" : "sslmode=disable";
            if (options != DEFAULT) {
                safe_options = @"$safe_options&$options";
            }


            var url = Uri.join_with_user(UriFlags.NONE, SCHEME, safe_user, safe_password, null, safe_host, safe_port, safe_db, safe_options, null);

            return(url.to_string());
        }

        public string backup_connection_string (){
            var ssl_mode = use_ssl ? "verify-full" : "disable";

            var base_str = @"user=$user password=$password port=$port host=$host dbname=$database application_name=$(Config.APP_NAME) sslmode=$ssl_mode";
            var builder = new StringBuilder(base_str);

            if (use_ssl) {
                builder.append(@" sslrootcert=$(cert_path) ");
            }

            return(builder.free_and_steal());
        }

        public string connection_string (int connection_timeout, int query_timeout){
            var ssl_mode = use_ssl ? "verify-full" : "disable";
            var options = @"\'-c statement_timeout=$(query_timeout * 1000)\'";

            var base_str = @"user=$user password=$password port=$port host=$host dbname=$database application_name=$(Config.APP_NAME) sslmode=$ssl_mode connect_timeout=$connection_timeout options=$options";
            var builder = new StringBuilder(base_str);

            if (use_ssl) {
                builder.append(@" sslrootcert=$(cert_path) ");
            }


            return(builder.free_and_steal());
        }

        /**
         * Make a deep copy of Connection
         */
        public Connection clone (){
            return((Connection) Json.gobject_deserialize(typeof (Connection), Json.gobject_serialize(this)));
        }

        /**
         * Parse Connection from a json string.
         */
        public static Connection ? deserialize (string json){
            try {
                var conn = (Connection) Json.gobject_from_data(typeof (Connection), json);

                return(conn);
            } catch (Error err) {
                debug(err.message);

                return(null);
            }
        }

        /**
         * Create a json representation of Connection.
         */
        public static string serialize (Connection conn){
            return(Json.gobject_to_data(conn, null));
        }
    }
}
