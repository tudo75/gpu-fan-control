namespace GpuFanControl {

    public class Application : Gtk.Application {

        private Gtk.ApplicationWindow window;
        private Gtk.HeaderBar headerbar;
        private Gtk.Label main_lbl;
        private Gtk.ScrolledWindow scroll_window;
        private Gtk.Box main_box;
        private Gtk.Grid toolbar;
        private Gtk.Button about_btn;
        private Gtk.Button xconfig_btn;
        private Gtk.Button reboot_btn;
        private Gtk.Button refresh_btn;
        private Gtk.Button set_speed_btn;
        private Gtk.Scale scale;
        private GLib.Settings settings;
        private const string APP_NAME = "GPU Fan Control";
        private const string VERSION = "1.0.0";
        private const string APP_ID = "com.github.tudo75.gpu-fan-control";
        private const string APP_LANG_DOMAIN = "gpu-fan-control";
        private const string APP_INSTALL_PREFIX = "/usr/local";
        private const int APP_WIDTH = 810; //610
        private const int APP_HEIGHT = 430; //430
        private string error_msg;

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

            // congfigure i18n localization
            Intl.setlocale (LocaleCategory.ALL, "");
            // TODO modify for production publishing
            string langpack_dir = Path.build_filename (APP_INSTALL_PREFIX, "share", "locale");
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
        public override void activate () {
            window = new Gtk.ApplicationWindow (this);
            window.set_default_size (APP_WIDTH, APP_HEIGHT);
            Gtk.Window.set_default_icon_name (APP_LANG_DOMAIN);
            init_style ();
            init_widgets ();
            init_headerbar ();
            init_main_panel ();
            init_toolbar ();
            create_window_structure ();
            window.show_all ();
            window.show ();
            window.present ();
            if (!refresh_smi ()) {
                show_dialog ("error", _("Error"), error_msg);
                error_msg = "";
            };
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
            settings = new GLib.Settings(APP_ID);
            headerbar = new Gtk.HeaderBar ();
            about_btn = new Gtk.Button ();
            scroll_window = new Gtk.ScrolledWindow (null, null);
            main_lbl = new Gtk.Label ("");
            xconfig_btn = new Gtk.Button ();
            reboot_btn = new Gtk.Button ();
            refresh_btn = new Gtk.Button ();
            set_speed_btn = new Gtk.Button ();
            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);

            // containers
            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            toolbar = new Gtk.Grid ();

            // vars
            error_msg = "";

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
            hbox_about_btn.pack_start(
                new Gtk.Image.from_icon_name (APP_LANG_DOMAIN,  Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_about_btn.pack_start (new Gtk.Label (_("About us")), true, true, 0);
            about_btn.add (hbox_about_btn);
            about_btn.clicked.connect (about_dialog);
            
            headerbar.pack_start (about_btn);
            window.set_titlebar (headerbar);
        }

        /**
         * init_main_panel:
         *
         * Constructor for the scrollable label in which display nvidia-smi results
         */
        private void init_main_panel () {
            main_lbl.get_style_context ().add_class ("main_lbl");
            main_lbl.set_vexpand (true);
            main_lbl.set_hexpand (true);
            scroll_window.add (main_lbl);
        }

        /**
         * init_toolbar:
         *
         * Constructor for the toolbar grid where are all the controls of the Application
         */
        private void init_toolbar () {
            Gtk.Box hbox_xconfig_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_xconfig_btn.pack_start(
                new Gtk.Image.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_xconfig_btn.pack_start (new Gtk.Label (_("Initialize Nvidia Xconfig")), true, true, 0);
            xconfig_btn.add (hbox_xconfig_btn);
            xconfig_btn.clicked.connect (set_config);
            if (settings.get_boolean("xconfig-init"))
                xconfig_btn.set_sensitive (false);

            Gtk.Box hbox_reboot_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_reboot_btn.pack_start(
                new Gtk.Image.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_reboot_btn.pack_start (new Gtk.Label (_("Reboot the system")), true, true, 0);
            reboot_btn.add (hbox_reboot_btn);
            reboot_btn.set_sensitive (false);
            reboot_btn.clicked.connect (reboot);

            scale.set_hexpand (true);
            scale.set_digits (0);
            scale.add_mark (0, Gtk.PositionType.TOP, "0");
            scale.add_mark (100, Gtk.PositionType.TOP, "100");
            scale.set_value (get_fan_speed());
           
            Gtk.Box hbox_refresh_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_refresh_btn.pack_start(
                new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_refresh_btn.pack_start (new Gtk.Label (_("Refresh")), true, true, 0);
            refresh_btn.add (hbox_refresh_btn);
            refresh_btn.clicked.connect (refresh_smi_void);

            Gtk.Box hbox_set_speed_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_set_speed_btn.pack_start(
                new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_set_speed_btn.pack_start (new Gtk.Label (_("Save")), true, true, 0);
            set_speed_btn.add (hbox_set_speed_btn);
            set_speed_btn.clicked.connect (set_speed);

            var frame_init_btns = new Gtk.Frame (_("First run config"));
            frame_init_btns.set_label_align ((float)0.1, (float)0.5);
            var grid_init_btns = new Gtk.Grid ();
            frame_init_btns.add (grid_init_btns);
            grid_init_btns.set_column_spacing (15);
            grid_init_btns.set_row_spacing (10);
            grid_init_btns.set_margin_top (10);
            grid_init_btns.set_margin_bottom (10);
            grid_init_btns.set_margin_start (10);
            grid_init_btns.set_margin_end (10);
            grid_init_btns.set_column_homogeneous (true);
            grid_init_btns.set_row_homogeneous (true);
            grid_init_btns.attach (xconfig_btn, 0, 0, 1, 1);
            grid_init_btns.attach (reboot_btn, 0, 1, 1, 1);

            var frame_set_speed = new Gtk.Frame (_("Set fan speed"));
            frame_set_speed.set_label_align ((float)0.04, (float)0.5);
            var grid_set_speed = new Gtk.Grid ();
            frame_set_speed.add (grid_set_speed);
            grid_set_speed.set_column_spacing (15);
            grid_set_speed.set_row_spacing (10);
            grid_set_speed.set_margin_top (10);
            grid_set_speed.set_margin_bottom (10);
            grid_set_speed.set_margin_start (10);
            grid_set_speed.set_margin_end (10);
            grid_set_speed.set_column_homogeneous (true);
            grid_set_speed.set_row_homogeneous (true);
            grid_set_speed.attach (scale, 0, 0, 3, 1);
            grid_set_speed.attach (refresh_btn, 0, 1, 1, 1);
            grid_set_speed.attach (set_speed_btn, 2, 1, 1, 1);
                
            toolbar.set_column_spacing (10);
            toolbar.set_row_spacing (10);
            toolbar.set_margin_top (10);
            toolbar.set_margin_bottom (10);
            toolbar.set_margin_start (10);
            toolbar.set_margin_end (10);
            toolbar.set_column_homogeneous (true);
            toolbar.set_row_homogeneous (true);
            toolbar.attach (frame_init_btns, 0, 0, 1, 2);
            toolbar.attach (frame_set_speed, 1, 0, 2, 2);
            /*
            toolbar.attach (xconfig_btn, 0, 0, 2, 1);
            toolbar.attach (reboot_btn, 2, 0, 2, 1);
            toolbar.attach (speed_lbl, 0, 1, 1, 1);
            toolbar.attach (scale, 1, 1, 2, 1);
            toolbar.attach (set_speed_btn, 3, 1, 1, 1);
             */
        }

        /**
         * create_window_structure:
         *
         * Combine every part of the Application
         */
        private void create_window_structure () {
            main_box.set_vexpand (true);
            main_box.add (scroll_window);
            main_box.add (toolbar);

            window.add (main_box);
        }

        /**
         * refresh_smi:
         *
         * Fetch nvidia-smi results and display results in the scrollable label of the main_panel
         *
         * @return a #bool value: true if the command has a successfull result, false otherwise
         */
        private bool refresh_smi () {
            try {
                string[] spawn_args = {"nvidia-smi"};
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
                    main_lbl.set_label (ls_stdout);
                    return true;
                } else if (ls_stderr != null) {
		            print ("stderr:\n" + ls_stderr);
                    main_lbl.set_label (ls_stderr);
                    error_msg = ls_stderr;
                    return false;
                }
                return true;

            } catch (SpawnError e) {
                print (e.message);
                main_lbl.set_label (e.message);
                error_msg = e.message;
                return false;
            }
        }

        private void refresh_smi_void () {
            refresh_smi ();
        }

        /**
         * get_fan_speed:
         *
         * Fetch nvidia-smi result for fan speed
         *
         * @return fan speed percent value as #int
         */
        private int get_fan_speed () {
            try {
                string[] spawn_args = {"nvidia-smi", "--query-gpu=fan.speed", "--format=csv,noheader,nounits"};
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
                    return int.parse (ls_stdout);
                } else if (ls_stderr != null) {
		            print ("stderr:\n");
                    print (ls_stderr);
                    return 1;
                }

                return 0;

            } catch (SpawnError e) {
                print (e.message);
                return 1;
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
        private bool exec_command (string[] cmds) {
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
                    error_msg = ls_stderr;
                    return false;
                }
                return true;
            } catch (SpawnError e) {
                print (e.message);
                error_msg = e.message;
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
                if (exec_command({"pkexec", "nvidia-xconfig", "-a", "--cool-bits=28", "--allow-empty-initial-configuration'"})) {
                    // success message
                    show_dialog ("info", _("Info"), _("Success! New X configuration file written to /etc/X11/xorg.conf"));
                    // update initialized key to keep track
                    settings.set_boolean ("xconfig-init", true);
                    // enable reboot button
                    reboot_btn.set_sensitive (true);
                    // disable xconfig button
                    xconfig_btn.set_sensitive (false);
                } else {
                    show_dialog ("error", _("Error"), error_msg);
                    error_msg = "";
                }
            } else {
                show_dialog ("error", _("Error"), error_msg);
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
                    show_dialog ("error", _("Error"), error_msg);
                    error_msg = "";
                }
            } else {
                show_dialog ("error", _("Error"), _("Reboot is required to implement the changes"));
                error_msg = "";
            }
        }

        /**
         * set_speed:
         *
         * Set fan speed.
         *
         * Show a dialog for success or error.
         */
        private void set_speed () {
            string val = ((int) scale.get_value ()).to_string ();
            // set the gpu for over clock
            bool first_cmd = exec_command ({"nvidia-settings", "-a", "[gpu:0]/GPUFanControlState=1"});
            // command to set the speed
            bool second_cmd = exec_command ({"nvidia-settings", "-a", "[fan]/GPUTargetFanSpeed=" + val});
            if (first_cmd && second_cmd) {
                show_dialog ("info", _("Info"), _("Fan Speed Set To ") + val);
            } else {
                show_dialog ("error", _("Error"), error_msg);
                error_msg = "";
            }
            if (!refresh_smi ()) {
                show_dialog ("error", _("Error"), error_msg);
                error_msg = "";
            };
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
        private int show_dialog (string type, string title, string message) {
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