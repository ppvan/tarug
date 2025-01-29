using GLib;

namespace Tarug {
    public class BackupService : Object {
        public BackupService(){}

        public async void backup_db (File dest, Connection conn, Vec<string> options) throws GLib.Error {
            // var flags      = SubprocessFlags.NONE;
            var flags = SubprocessFlags.STDERR_PIPE;
            Vec<string> args = new Vec<string>();
            args.append("pg_dump");

            foreach (var item in options) {
                args.append(item);
            }

            args.append(conn.backup_connection_string());
            args.append("-f");
            args.append(dest.get_path());

            var subprocess = new Subprocess.newv(args.as_array(), flags);

            // Wait for the subprocess to finish asynchronously
            yield subprocess.wait_async ();

            string ? stderr_buf = null;

            // Get the exit status
            int exit_status = subprocess.get_exit_status();

            if (exit_status != 0) {
                yield subprocess.communicate_utf8_async (null, null, null, out stderr_buf);

                throw new tarugError.BACKUP_ERROR(stderr_buf);
            }
        }

        public async void restore_db (File source, Connection conn, Vec<string> options) throws GLib.Error {
            var flags = SubprocessFlags.STDERR_PIPE;
            Vec<string> args = new Vec<string>();
            args.append("pg_restore");
            args.append(source.get_path());

            foreach (var item in options) {
                args.append(item);
            }
            args.append("--dbname");
            args.append(conn.backup_connection_string());

            var subprocess = new Subprocess.newv(args.as_array(), flags);

            // Wait for the subprocess to finish asynchronously
            yield subprocess.wait_async ();

            string ? stderr_buf = null;

            // Get the exit status
            int exit_status = subprocess.get_exit_status();

            if (exit_status != 0) {
                yield subprocess.communicate_utf8_async (null, null, null, out stderr_buf);

                throw new tarugError.BACKUP_ERROR(stderr_buf);
            }
        }
    }
}
