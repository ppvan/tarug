/* application.vala
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
using Csv;

namespace Psequel {
    public enum ApplicationStyle {
        SYSTEM = 0,
        LIGHT,
        DARK
    }

    public class Application : Adw.Application {
        /*
         * Static field for easy access in other places.
         * If need to create many application instance (rarely happens) reconsider this approach.
         */
        public static ThreadPool<Worker> background;

        public int color_scheme { get; set; }
        public const int MAX_COLUMNS = 24;
        public const int PRE_ALLOCATED_CELL = 256;
        public const int BATCH_SIZE = 32;
        public const int MIGRATION_VERSION = 1;

        public static List<uint> tasks;
        public static bool is_running = false;
        public static Settings settings;

        public Application(){
            Object(application_id: Config.APP_ID, flags: ApplicationFlags.DEFAULT_FLAGS);
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "new-window", this.on_new_window },
                { "quit", this.quit }
            };
            this.add_action_entries(action_entries, this);


            this.set_accels_for_action("app.new-window", { "<Ctrl><Shift>n" });
            this.set_accels_for_action("app.quit", { "<primary>q" });
            this.set_accels_for_action("app.preferences", { "<primary>comma" });

            this.set_accels_for_action("win.import", { "<Ctrl><Shift>o" });
            this.set_accels_for_action("win.export", { "<Ctrl><Shift>e" });
            this.set_accels_for_action("win.run-query", { "<Ctrl>Return" });

            // this.set_accels_for_action ("conn.dupplicate", { "<Ctrl>D" });
        }

        public override void activate (){
            base.activate();
            var window = new_window();
            window.present();
        }

        public override void startup (){
            base.startup();
            GtkSource.init();
            set_up_logging();

            Application.settings = new Settings(this.application_id);
            settings.bind("color-scheme", this, "color_scheme", SettingsBindFlags.GET);
            this.notify["color-scheme"].connect(update_color_scheme);

            Application.tasks = new List<uint> ();
            Application.is_running = true;

            debug("Begin to load resources");
            try {
                // Don't change the max_thread because libpq did not support many query with 1 connection.
                background = new ThreadPool<Worker>.with_owned_data ((worker) => {
                    worker.run();
                }, 1, false);
            } catch (ThreadError err) {
                debug(err.message);
                assert_not_reached();
            }
            debug("Resources loaded");
        }

        public override void shutdown (){
            base.shutdown();
            Application.is_running = false;
        }

        public void update_color_scheme (){
            switch (this.color_scheme) {
                case ApplicationStyle.SYSTEM:
                    style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
                    break;

                case ApplicationStyle.DARK:
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                    break;

                case ApplicationStyle.LIGHT:
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                    break;

                default:
                    assert_not_reached();
            }
        }

        public void on_something (){
            debug("Dark: %b", style_manager.dark);
            if (style_manager.dark) {
                style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
            } else {
                style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
            }

            // style_manager.dark = !style_manager.dark;
        }

        public static int main (string[] args){
            ensure_types();
            var app = new Psequel.Application();

            return app.run(args);
        }

        /* register needed types, allow me to ref a template inside a template */
        private static void ensure_types (){
            typeof (Psequel.StyleSwitcher).ensure();
            typeof (Psequel.TableRow).ensure();
            typeof (Psequel.TableGraph).ensure();
            typeof (Psequel.WhereEntry).ensure();
            typeof (Psequel.DataCell).ensure();
            typeof (Psequel.BackupDialog).ensure();
            typeof (Psequel.RestoreDialog).ensure();
            typeof (Psequel.SchemaView).ensure();

            typeof (Psequel.ConnectionRow).ensure();
            typeof (Psequel.ConnectionView).ensure();
            typeof (Psequel.QueryResults).ensure();
            typeof (Psequel.QueryEditor).ensure();
            typeof (Psequel.EditRowDialog).ensure();
            typeof (Psequel.TableStructureView).ensure();
            typeof (Psequel.TableColumnInfo).ensure();
            typeof (Psequel.TableIndexInfo).ensure();
            typeof (Psequel.ViewStructureView).ensure();
            typeof (Psequel.TableDataView).ensure();
            typeof (Psequel.ViewDataView).ensure();
        }

        private void on_about_action (){
            string app_data_resource = "/me/ppvan/psequel/appdata";
            var about = new Adw.AboutDialog.from_appdata (app_data_resource, Config.VERSION);
            about.present (this.active_window);
        }

        private void on_new_window (){
            var window = new_window();
            window.present();
        }

        private void on_preferences_action (){
            var preference = new PreferencesWindow(){
            };

            preference.present(this.active_window);
        }

        /**
         * Create a window and inject resources.
         *
         * Because child widget is created before window, signals can only be connect when window is init.
         * This result to another event to notify window is ready and widget should setup signals
         */
        private Window new_window (){
            // Clone all singleton instances for each window
            Container.clone();
            EventBus.clone();
            create_viewmodels();
            var window = new Window(this);

            return window;
        }

        private Container create_viewmodels (){
            var container = Container.instance();
            var app_data_dir = Path.build_filename(GLib.Environment.get_user_data_dir(), Config.APP_ID);
            DirUtils.create_with_parents(app_data_dir, 0777);

            var db_file = File.new_for_path(Path.build_filename(app_data_dir, "database.sqlite3"));

            // global things
            container.register(this);
            container.register(Application.settings);


            // services
            var storage_service = new StorageService(db_file.get_path());
            container.register(storage_service);

            var migration_service = new MigrationService();
            migration_service.set_up_baseline();
            migration_service.apply_migrations(Application.MIGRATION_VERSION);
            container.register(migration_service);


            var sql_service = new SQLService(Application.background);
            var schema_service = new SchemaService(sql_service);
            var connection_repo = new ConnectionRepository();
            var query_repo = new QueryRepository();
            var navigation = new NavigationService();
            var export = new ExportService();
            var backup_service = new BackupService();
            var completer = new CompleterService(sql_service);

            // viewmodels
            var conn_vm = new ConnectionViewModel(connection_repo, sql_service, navigation);
            var sche_vm = new SchemaViewModel(schema_service);
            var table_vm = new TableViewModel(sql_service);
            var view_vm = new ViewViewModel(sql_service);
            // var table_structure_vm = new TableStructureViewModel(sql_service);
            var view_structure_vm = new ViewStructureViewModel(sql_service);
            var table_data_vm = new TableDataViewModel(sql_service);
            var view_data_vm = new ViewDataViewModel(sql_service);
            var query_history_vm = new QueryHistoryViewModel(sql_service, query_repo);
            var query_vm = new QueryViewModel(query_history_vm);

            container.register(sql_service);
            container.register(backup_service);
            container.register(completer);
            container.register(schema_service);
            container.register(export);
            container.register(connection_repo);
            container.register(navigation);
            container.register(conn_vm);
            container.register(sche_vm);
            container.register(table_vm);
            container.register(view_vm);
            // container.register(table_structure_vm);
            container.register(view_structure_vm);
            container.register(table_data_vm);
            container.register(view_data_vm);
            container.register(query_history_vm);
            container.register(query_vm);


            return container;
        }
    }
}
