/*
 * application.vala
 * 
 * Copyright 2021 Nicola tudino <nicola.tudino@gmail.com>
 * 
 * This file is part of GpuFanControl.
 *
 * GpuFanControl is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * GpuFanControl is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GpuFanControl.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */


 namespace GpuFanControl {

    public class Application : Gtk.Application {

        private Gtk.ApplicationWindow window;
        private Gtk.HeaderBar headerbar;
        private Gtk.Notebook note_panel;
        private int[] gpu_ids;
        private string[] gpu_names;
        private Gtk.Grid grid_init_btns;
        private Gtk.Frame frame_init_btns;

        private Gtk.Box[] main_box;
        private Gtk.Button about_btn;
        private Gtk.Button xconfig_btn;
        private Gtk.Button reboot_btn;
        private GLib.Settings settings;
        private const string APP_NAME = "GPU Fan Control";
        private const string VERSION = "1.0.0";
        private const string APP_ID = "com.github.tudo75.gpu-fan-control";
        private const string APP_LANG_DOMAIN = "gpu-fan-control";
        private const string APP_INSTALL_PREFIX = "/usr/local";
        private int APP_WIDTH; //810
        private int APP_HEIGHT; //320
        // TODO create get/set methods
        private string error_msg;

        private uint[] timeout_id;

        // TODO set to false for production
        private const bool DEVEL = false;


        /**
         * Application:
         *
         * Main application constructor
         */
        public Application () {
            application_id = APP_ID;
            flags |= GLib.ApplicationFlags.HANDLES_OPEN;

            // For Wayland: must be the same name of the exec in *.desktop file
            GLib.Environment.set_prgname (APP_ID);

            settings = new GLib.Settings(APP_ID);
            APP_WIDTH = settings.get_int ("window-width");
            APP_HEIGHT = settings.get_int ("window-height");

            // congfigure i18n localization
            Intl.setlocale (LocaleCategory.ALL, "");
            string langpack_dir = Path.build_filename (APP_INSTALL_PREFIX, "share", "locale");
            // TODO modify for production publishing
            if (DEVEL) {
                langpack_dir = Path.build_filename ("/", "home", "nick", "gpu-fan-control", "po");
            }
            print (langpack_dir + "\n");
            Intl.bindtextdomain (APP_ID, langpack_dir);
            Intl.bind_textdomain_codeset (APP_ID, "UTF-8");
            Intl.textdomain (APP_ID);
        }

        /**
         * {@inheritDoc}
         */
        protected override void activate () {
            window = new Gtk.ApplicationWindow (this);
            window.set_default_size (APP_WIDTH, APP_HEIGHT);
            // window.set_size_request (APP_WIDTH, APP_HEIGHT);
            window.set_resizable (false);
            window.window_position = Gtk.WindowPosition.CENTER;
            Gtk.Window.set_default_icon_name (APP_LANG_DOMAIN);
            this.init_style ();
            this.init_widgets ();
            this.init_headerbar ();
            this.init_xconfig_toolbar ();
            this.create_window_structure ();
            window.show_all ();
            window.show ();
            window.present ();
        }

        /**
         * {@inheritDoc}
         */
        protected override void shutdown () {
            print("exit");
            foreach (var id in timeout_id)
                GLib.Source.remove (id);
            base.shutdown ();
        }

        /**
         * init_style:
         *
         * Add custom style sheet to the Application
         */
        private void init_style () {
            Gtk.CssProvider css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("/com/github/tudo75/gpu-fan-control/style.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

        /**
         * init_widgets:
         *
         * Initiaize widgets objects and vars
         */
        private void init_widgets () {
            // init settings retrieve
            headerbar = new Gtk.HeaderBar ();
            about_btn = new Gtk.Button ();

            note_panel = new Gtk.Notebook ();
            gpu_ids = this.get_gpu_ids ();
            gpu_names = this.get_gpu_names ();

            xconfig_btn = new Gtk.Button ();
            reboot_btn = new Gtk.Button ();

            // containers
            for (var i = 0; i < gpu_ids.length; i++)
                main_box += new GpuFanControl.NotebookPane (this, gpu_ids[i]);

            // vars
            this.set_error_msg ("");

            // window config
            window.set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        }

        /**
         * init_headerbar:
         *
         * #Gtk.HeaderBar constructor for the Application
         */
        private void init_headerbar () {
            headerbar.set_title (APP_NAME);
            headerbar.set_hexpand (true);
            headerbar.set_show_close_button (true);

            Gtk.Box hbox_about_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_about_btn.pack_start (
                new Gtk.Image.from_icon_name (APP_LANG_DOMAIN,  Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_about_btn.pack_start (new Gtk.Label (_("About us")), true, true, 0);
            about_btn.add (hbox_about_btn);
            about_btn.clicked.connect (this.about_dialog);
            
            headerbar.pack_start (about_btn);
            window.set_titlebar (headerbar);
        }

        private void init_xconfig_toolbar () {
            Gtk.Box hbox_xconfig_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_xconfig_btn.pack_start (
                new Gtk.Image.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_xconfig_btn.pack_start (new Gtk.Label (_("Initialize Nvidia Xconfig")), true, true, 0);
            xconfig_btn.add (hbox_xconfig_btn);
            xconfig_btn.clicked.connect (this.set_config);
            if (settings.get_boolean ("xconfig-init"))
                xconfig_btn.set_sensitive (false);

            Gtk.Box hbox_reboot_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_reboot_btn.pack_start (
                new Gtk.Image.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_reboot_btn.pack_start (new Gtk.Label (_("Reboot the system")), true, true, 0);
            reboot_btn.add (hbox_reboot_btn);
            reboot_btn.set_sensitive (false);
            reboot_btn.clicked.connect (this.reboot);

            grid_init_btns = new Gtk.Grid ();
            grid_init_btns.set_column_spacing (15);
            grid_init_btns.set_row_spacing (10);
            grid_init_btns.set_margin_top (10);
            grid_init_btns.set_margin_bottom (10);
            grid_init_btns.set_margin_start (10);
            grid_init_btns.set_margin_end (10);
            grid_init_btns.set_column_homogeneous (true);
            grid_init_btns.set_row_homogeneous (true);
            grid_init_btns.attach (xconfig_btn, 0, 0, 1, 1);
            grid_init_btns.attach (new Gtk.Label (" "), 1, 0, 1, 1);
            grid_init_btns.attach (new Gtk.Label (" "), 2, 0, 1, 1);
            grid_init_btns.attach (reboot_btn, 3, 0, 1, 1);
            frame_init_btns = new Gtk.Frame (_("First run config"));
            frame_init_btns.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
            frame_init_btns.set_border_width (2);
            frame_init_btns.add (grid_init_btns);
            frame_init_btns.set_margin_top (5);
            frame_init_btns.set_margin_bottom (5);
            frame_init_btns.set_margin_start (5);
            frame_init_btns.set_margin_end (5);
        }

        /**
         * create_window_structure:
         *
         * Combine every part of the Application
         */
        private void create_window_structure () {
            note_panel.set_tab_pos (Gtk.PositionType.LEFT);
            note_panel.popup_enable ();
            note_panel.set_scrollable (true);

            for (var i = 0; i < main_box.length; i++) {
                main_box[i].set_vexpand (true);
                note_panel.append_page (main_box[i], new Gtk.Label (gpu_names[i]));
            }

            var window_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            window_box.pack_start (frame_init_btns, true, false, 0);
            window_box.pack_start (note_panel, true, true, 0);

            window.add (window_box);
        }

        /**
         *
         */
        public void add_timeout_item (uint id) {
            this.timeout_id += id;
        }

        /**
         *
         */
        public void set_error_msg (string message) {
            this.error_msg = message;
        }

        /**
         *
         */
        public string get_error_msg () {
            return this.error_msg;
        }

        /**
         * get_gpu_ids:
         *
         *
         *
         * @return: ar array of the gpu indexes found on pc
         */
        private int[] get_gpu_ids () {
            var indexes = new int[] {-1};
            try {
                string[] spawn_args = {"nvidia-smi", "--query-gpu=count", "--format=csv,noheader,nounits"};
                string[] spawn_env = Environ.get ();
                string ls_stdout;
                string ls_stderr;
                int ls_status;
                Process.spawn_sync ("/",
                                    spawn_args,
                                    spawn_env,
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    out ls_stdout,
                                    out ls_stderr,
                                    out ls_status);

                // Output: ````
                if (ls_stdout != null) {
		            // print ("stdout:\n");
                    // print (ls_stdout);
                    int count = int.parse (ls_stdout);
                    for (var i = 0; i < count; i++)
                        indexes[i] = i;
                } else if (ls_stderr != null) {
		            print ("stderr:\n");
                    print (ls_stderr + "\n");
                }
                return indexes;
            } catch (SpawnError e) {
                print (e.message);
                return indexes;
            }
        }

        /**
         * get_gpu_ids:
         *
         *
         *
         * @return: ar array of the gpu indexes found on pc
         */
        private string[] get_gpu_names () {
            var names = new string[] {""};
            try {
                string[] spawn_args = {"nvidia-smi", "--query-gpu=name", "--format=csv,noheader,nounits"};
                string[] spawn_env = Environ.get ();
                string ls_stdout;
                string ls_stderr;
                int ls_status;
                Process.spawn_sync ("/",
                                    spawn_args,
                                    spawn_env,
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    out ls_stdout,
                                    out ls_stderr,
                                    out ls_status);

                // Output: ````
                if (ls_stdout != null) {
		            // print ("stdout:\n");
                    // print (ls_stdout);
                    names = ls_stdout.split ("\n");
                } else if (ls_stderr != null) {
		            print ("stderr:\n");
                    print (ls_stderr + "\n");
                }
                return names;
            } catch (SpawnError e) {
                print (e.message);
                return names;
            }
        }

        /**
         * exec_command:
         * 
         * Execute command line instruction assembling cmds parts.
         *
         * @param cmds (type string[]): each part of the command whitout the spaces
         * @return a #bool value: true for command success, false otherwise
         */
        public bool exec_command (string[] cmds) {
            try {
                string[] spawn_args = cmds;
                string[] spawn_env = Environ.get ();
                string ls_stdout;
                string ls_stderr;
                int ls_status;

                Process.spawn_sync ("/",
                                    spawn_args,
                                    spawn_env,
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    out ls_stdout,
                                    out ls_stderr,
                                    out ls_status);


                // Output: ````
                if (ls_stdout != null) {
		            print ("stdout:\n" + ls_stdout);
                    return true;
                } else if (ls_stderr != null) {
		            print ("stderr:\n" + ls_stderr);
                    this.set_error_msg (ls_stderr);
                    return false;
                }
                return true;
            } catch (SpawnError e) {
                print (e.message);
                this.set_error_msg (e.message);
                return false;
            }
        }

        /**
         * Write new X configuration file in /etx/X11
         *
         * Show a dialog for success or error.
         */
        private void set_config () {
            // checking if nvidia-smi is installed
            if (exec_command ({"nvidia-smi"})) {
                // allowing the gpu to overclock manually
                if (exec_command({"pkexec", "nvidia-xconfig", "-a", "--cool-bits=28", "--allow-empty-initial-configuration"})) {
                    // success message
                    this.show_dialog ("info", _("Info"), _("Success! New X configuration file written to /etc/X11/xorg.conf"));
                    // update initialized key to keep track
                    settings.set_boolean ("xconfig-init", true);
                    // enable reboot button
                    reboot_btn.set_sensitive (true);
                    // disable xconfig button
                    xconfig_btn.set_sensitive (false);
                } else {
                    this.show_dialog ("error", _("Error"), this.get_error_msg ());
                    error_msg = "";
                }
            } else {
                this.show_dialog ("error", _("Error"), error_msg);
                error_msg = "";
            }
        }

        /**
         * reboot:
         *
         * Execute a system reboot.
         *
         * Show an error dialog in case super user password is wrong or action is cancelled.
         */
        private void  reboot () {
            int result = show_dialog ("question", _("Reboot"), _("Do you want to reboot?"));
            if (result == Gtk.ResponseType.YES) {
                if (!exec_command ({"pkexec", "reboot"})) {
                    this.show_dialog ("error", _("Error"), error_msg);
                    error_msg = "";
                }
            } else {
                this.show_dialog ("error", _("Error"), _("Reboot is required to implement the changes"));
                error_msg = "";
            }
        }

        /**
         * about_dialog:
         *
         * Create and display a #Gtk.AboutDialog window.
         */            
        private void about_dialog () {
            // Configure the dialog:
            Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
            dialog.set_destroy_with_parent (true);
            dialog.set_transient_for (window);
            dialog.set_modal (true);

            dialog.set_logo_icon_name (APP_LANG_DOMAIN);

            dialog.authors = {"Nicola Tudino <tudo75@gmail.com>"};
            dialog.artists = {"Nicola Tudino <tudo75@gmail.com>"};
            dialog.documenters = {"Nicola Tudino <tudo75@gmail.com>"};
            dialog.translator_credits = ("Nicola Tudino <tudo75@gmail.com>");

            dialog.program_name = APP_NAME;
            dialog.comments = _("GUI fan controller for Nvidia GPU");
            dialog.copyright = _("Copyright");
            dialog.version = VERSION;

            dialog.set_license_type (Gtk.License.GPL_3_0_ONLY);

            dialog.website = "http://github.com/tudo75/gpu-fan-control";
            dialog.website_label = "Repository Github";

            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                    dialog.hide_on_delete ();
                }
            });

            // Show the dialog:
            dialog.present ();
        }

        /**
         * Open a popup modal dialog.
         *
         * @param type {@link string} - the #Gtk.Dialog type (error, info, question)
         * @param title {@link string}: the #Gtk.Dialog title
         * @param message {@link string}: the #Gtk.Dialog message to show
         * @return an {@link int} value corresponding to the clicked {@link Gtk.ButtonsType}
         */
        public int show_dialog (string type, string title, string message) {
            // Always print the error message first
            if (type == "error")
                print (type + " - " + title + ": " + message + "\n");
            // Then display a Gtk Popup
            var popup = new Gtk.Dialog.with_buttons (title, window, Gtk.DialogFlags.MODAL);

            var icon = new Gtk.Image ();
            switch (type) {
                case "error": {
                    popup.add_button (_("Close"), Gtk.ButtonsType.CLOSE); // return 2
                    icon = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
                    break;
                };
                case "info": {
                    popup.add_button (_("Close"), Gtk.ButtonsType.CLOSE); // return 2
                    icon = new Gtk.Image.from_icon_name ("dialog-info", Gtk.IconSize.DIALOG);
                    break;
                };
                case "question": {
                    popup.add_button (_("Yes"), Gtk.ButtonsType.OK); // return 1
                    popup.add_button (_("No"), Gtk.ButtonsType.CANCEL); // return 3
                    icon = new Gtk.Image.from_icon_name ("dialog-question", Gtk.IconSize.DIALOG);
                    break;
                };
            }

            Gtk.HeaderBar h_bar = new Gtk.HeaderBar ();
            h_bar.set_title (title);
            h_bar.set_show_close_button (true);
            popup.set_titlebar (h_bar);

            Gtk.Label message_label = new Gtk.Label (message);
            message_label.set_hexpand (true);
            message_label.set_line_wrap (true);
            message_label.set_size_request (settings.get_int ("window-width") - 140, 1);
            var box = popup.get_child () as Gtk.Box;
            box.set_border_width (12);
            var grid = new Gtk.Grid ();
            grid.set_column_spacing (12);
            box.pack_start (grid, false, false, 0);
            grid.attach (icon, 0, 0, 1, 1);
            grid.attach (message_label, 1, 0, 1, 1);

            popup.set_modal (true);
            popup.set_default_size (settings.get_int ("window-width") - 60, 1);
            popup.show_all ();

            int response = popup.run ();
            popup.destroy ();
            print ((response).to_string () + "\n");
            return response;
        }
    }

    public static int main (string[] args) {
        var application = new Application ();
        return application.run (args);
    }
}
