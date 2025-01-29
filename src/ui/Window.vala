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

using GLib;

namespace Tarug {
    [GtkTemplate(ui = "/io/github/ppvan/tarug/gtk/window.ui")]
    public class Window : Adw.ApplicationWindow {
        const ActionEntry[] ACTIONS = {
            { "import", import_connection },
            { "export", export_connection },
            { "backup", backup_database },
            { "restore", restore_database },

            { "run-query", run_query },
        };

        public NavigationService navigation { get; private set; }
        public ConnectionViewModel connection_viewmodel { get; construct; }
        public QueryViewModel query_viewmodel { get; private set; }
        public BackupService backup_service { get; private set; }

        private Settings ? settings;
        private BackupDialog backup_dialog;
        private RestoreDialog restore_dialog;



        public Window(Application app){
            Object(
                application : app
            );
        }

        construct {
            this.navigation = autowire<NavigationService> ();
            this.connection_viewmodel = autowire<ConnectionViewModel> ();
            this.query_viewmodel = autowire<QueryViewModel> ();
            this.settings = autowire<Settings> ();
            this.backup_service = autowire<BackupService>();
            settings.bind("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
            settings.bind("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
            this.add_action_entries(ACTIONS, this);
        }

        public void add_toast (Adw.Toast toast){
            overlay.add_toast(toast);
        }

        // Actions:
        public void run_query (){
            if (query_viewmodel == null) {
                return;
            }

            query_viewmodel.run_selected_query.begin();
        }

        public void import_connection (){
            open_file_dialog.begin("Import connections");
        }

        public void export_connection (){
            save_file_dialog.begin("Export connections");
        }

        public void backup_database (){
            this.backup_dialog = new BackupDialog(connection_viewmodel);
            var window = get_parrent_window(this);

            backup_dialog.on_backup.connect((conn, options) => {
                save_backup_dialog.begin(conn, options, (obj, res) => {
                    // backup_dialog.close();
                });
            });

            backup_dialog.present(window);
        }

        public void restore_database (){
            restore_dialog = new RestoreDialog(this.connection_viewmodel);
            var window = get_parrent_window(this);

            restore_dialog.on_restore.connect((conn, options) => {
                save_restore_dialog.begin(conn, options, (obj, res) => {
                    restore_dialog.close();
                });
            });

            restore_dialog.present(window);
        }

        private async void open_file_dialog (string title = "Open File"){
            var filter = new Gtk.FileFilter();
            filter.add_mime_type("application/json");

            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(filter);

            var window = (Window) get_parrent_window(this);

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = File.new_for_path(Environment.get_home_dir()),
                title = title,
                initial_name = "connections.json",
                default_filter = filter,
                filters = filters
            };

            uint8[] contents;

            try {
                var file = yield file_dialog.open (window, null);

                yield file.load_contents_async (null, out contents, null);

                var json_str = (string) contents;
                var conns = ValueConverter.deserialize_connection(json_str);
                connection_viewmodel.import_connections(conns);

                var toast = new Adw.Toast(@"Loaded $(conns.length ()) connections"){
                    timeout = 3,
                };
                window.add_toast(toast);
            } catch (Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };
                window.add_toast(toast);
            }
        }

        private async void save_file_dialog (string title = "Save to file"){
            var filter = new Gtk.FileFilter();

            filter.add_mime_type("application/json");

            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(filter);

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = File.new_for_path(Environment.get_home_dir()),
                title = title,
                initial_name = "connections.json",
                default_filter = filter,
                filters = filters,
            };

            var conns = connection_viewmodel.export_connections();
            var content = ValueConverter.serialize_connection(conns);
            var bytes = new Bytes.take(content.data); // Move data to byte so it live when out scope
            var window = (Window) get_parrent_window(this);

            try {
                var file = yield file_dialog.save (window, null);

                yield file.replace_contents_bytes_async (bytes, null, false, FileCreateFlags.NONE, null, null);

                var toast = new Adw.Toast("Data saved successfully."){
                    timeout = 2,
                };
                window.add_toast(toast);
            } catch (Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };
                window.add_toast(toast);
            }
        }

        private async void save_backup_dialog (Connection conn, Vec<string> options){
            var custom_filter = new Gtk.FileFilter();
            custom_filter.add_mime_type("text/x-sql");
            custom_filter.add_mime_type("application/x-tar");
            custom_filter.add_mime_type("application/octet-stream");

            var all_files = new Gtk.FileFilter();
            all_files.add_pattern("*");
            all_files.set_filter_name("All Files");

            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(custom_filter);
            filters.append(all_files);

            var local = time_local();
            var dbname = conn.database ?? "database";
            var ext = backup_dialog.get_extension();
            var initial_name = @"$(dbname)-backup-$(local)$(ext)";

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = File.new_for_path(Environment.get_home_dir()),
                title = backup_dialog.is_choose_directory() ? "Select target directory" : "Select target file",
                initial_name = initial_name,
                default_filter = custom_filter,
                filters = filters,
            };

            var window = get_parrent_window(this);
            try {
                File ? file = null;
                if (backup_dialog.is_choose_directory()) {
                    file = yield file_dialog.select_folder (window, null);
                } else {
                    file = yield file_dialog.save (window, null);
                }

                yield backup_service.backup_db (file, conn, options);

                var toast = new Adw.Toast(@"Backup $dbname successfully"){
                    timeout = 2,
                };
                window.add_toast(toast);
            } catch (Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };
                window.add_toast(toast);
            }
        }

        private async void save_restore_dialog (Connection conn, Vec<string> options){
            var custom_filter = new Gtk.FileFilter();
            custom_filter.add_mime_type("text/x-sql");
            custom_filter.add_mime_type("application/x-tar");
            custom_filter.add_mime_type("application/octet-stream");
            custom_filter.set_filter_name("Backup file");

            var all_files = new Gtk.FileFilter();
            all_files.add_pattern("*");
            all_files.set_filter_name("All Files");
            var filters = new ListStore(typeof (Gtk.FileFilter));
            filters.append(custom_filter);
            filters.append(all_files);

            var local = time_local();
            var dbname = conn.database ?? "database";
            var ext = restore_dialog.get_extension();
            var initial_name = @"$(dbname)-backup-$(local)$(ext)";

            var file_dialog = new Gtk.FileDialog(){
                modal = true,
                initial_folder = File.new_for_path(Environment.get_home_dir()),
                title = restore_dialog.is_choose_directory() ? "Select target directory" : "Select target file",
                initial_name = initial_name,
                default_filter = custom_filter,
                filters = filters,
            };

            var window = get_parrent_window(this);
            try {
                File ? file = null;
                if (restore_dialog.is_choose_directory()) {
                    file = yield file_dialog.select_folder (window, null);
                } else {
                    file = yield file_dialog.open (window, null);
                }

                yield backup_service.restore_db (file, conn, options);

                var toast = new Adw.Toast(@"Restore $dbname successfully"){
                    timeout = 2,
                };
                window.add_toast(toast);
            } catch (Error err) {
                debug(err.message);

                var toast = new Adw.Toast(err.message){
                    timeout = 3,
                };
                window.add_toast(toast);
            }
        }

        [GtkChild]
        private unowned Adw.ToastOverlay overlay;
    }
}
