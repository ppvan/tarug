namespace Tarug {
    public class MigrationService : Object {
        private StorageService storage;

        public MigrationService(){
            this.storage = autowire<StorageService>();
        }

        public void set_up_baseline (){
            try {
                uint8[] file_content;
                string ? err_msg = null;

                debug("Setup database baseline");
                var file = File.new_for_uri("resource:///io/github/ppvan/tarug/migrations/version-0.sql");

                file.load_contents(null, out file_content, null);
                storage.exec((string) file_content, out err_msg);

                if (err_msg != null) {
                    debug("Sqlite Error: %s", err_msg);
                }
            } catch (GLib.Error err) {
                debug("Error: %s", err.message);
            }
        }

        public void apply_migrations (int latest_version){
            int current_version = fetch_version_num();
            for (int i = current_version + 1; i <= latest_version; i++) {
                apply_migration(i);
            }
        }

        private void apply_migration (int version){
            try {
                uint8[] file_content;
                string ? err_msg = null;

                debug("Apply migrations version: %d", version);
                var file = File.new_for_uri("resource:///io/github/ppvan/tarug/migrations/version-%d.sql".printf(version));

                file.load_contents(null, out file_content, null);
                storage.exec((string) file_content, out err_msg);

                if (err_msg != null) {
                    debug("Sqlite Error: %s", err_msg);
                }
            } catch (GLib.Error err) {
                debug("Error: %s", err.message);
            }
        }

        private int fetch_version_num (){
            string ? err_msg;

            var result = storage.exec("SELECT version_num FROM migrations LIMIT 1;", out err_msg);

            if (err_msg != null) {
                if ("no such table: migrations" in err_msg) {
                    return(0);
                }
                debug("SqliteError: %s", err_msg);
            }

            if (result.rows <= 0) {
                debug("Empty migrations table");

                return(0);
            }

            var version_str = result[0][0];

            return(int.parse(version_str));
        }
    }
}
