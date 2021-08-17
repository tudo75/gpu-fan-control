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
        private Gtk.Grid main_grid;
        private GpuFanControl.Meter meter;
        private GpuFanControl.Gauge gauge;
        private Gtk.Frame meter_frame;
        private Gtk.Frame gauge_frame;
        private Gtk.Frame data_frame;
        // query order: name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free
        private Gtk.Label gpu_name;
        private Gtk.Label gpu_driver_version;
        private Gtk.Label gpu_fan_speed;
        private Gtk.Label gpu_temp;
        private Gtk.Label gpu_time;
        private Gtk.Label gpu_memory_used;
        private Gtk.Label gpu_vbios_version;
        private Gtk.Label gpu_pstate;
        private Gtk.Label gpu_utilization_gpu;
        private Gtk.Label gpu_index;

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
        private int APP_WIDTH; //810
        private int APP_HEIGHT; //320
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
        public override void activate () {
            window = new Gtk.ApplicationWindow (this);
            window.set_default_size (APP_WIDTH, APP_HEIGHT);
            // window.set_size_request (APP_WIDTH, APP_HEIGHT);
            window.set_resizable (false);
            window.window_position = Gtk.WindowPosition.CENTER;
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

            meter.fit_size (meter_frame);
            gauge.fit_size (gauge_frame);

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
            headerbar = new Gtk.HeaderBar ();
            about_btn = new Gtk.Button ();
            
            scroll_window = new Gtk.ScrolledWindow (null, null);
            main_grid = new Gtk.Grid ();
            data_frame = new Gtk.Frame (_("Gpu data"));
            meter_frame = new Gtk.Frame (_("Temperature"));
            gauge_frame = new Gtk.Frame (_("Fan speed"));
            gpu_name = new Gtk.Label ("");
            gpu_fan_speed = new Gtk.Label ("");
            gpu_driver_version = new Gtk.Label ("");
            gpu_temp = new Gtk.Label ("");
            gpu_time = new Gtk.Label ("");
            gpu_memory_used = new Gtk.Label ("");
            gpu_vbios_version = new Gtk.Label ("");
            gpu_pstate = new Gtk.Label ("");
            gpu_utilization_gpu = new Gtk.Label ("");
            gpu_index = new Gtk.Label ("");

            xconfig_btn = new Gtk.Button ();
            reboot_btn = new Gtk.Button ();
            refresh_btn = new Gtk.Button ();
            set_speed_btn = new Gtk.Button ();
            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);

            meter = new GpuFanControl.Meter (Gtk.Orientation.VERTICAL, 0, 120, true, false);
            gauge = new GpuFanControl.Gauge (0, 100, GpuFanControl.Gauge.Position.LEFT, true);

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
            hbox_about_btn.pack_start (
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
            meter.set_size (160, 240);
            meter.set_halign (Gtk.Align.CENTER);
            meter.set_hexpand (false);
            meter.set_vexpand (true);
            gauge.set_size (140, 240);
            gauge.set_halign (Gtk.Align.CENTER);
            gauge.set_hexpand (false);
            gauge.set_vexpand (true);
            refresh_smi ();

            meter_frame.set_label_align ((float)0.1, (float)0.5);
            // meter_frame.set_halign (Gtk.Align.CENTER);
            meter_frame.add (meter);
            meter_frame.set_hexpand (false);
            meter_frame.set_vexpand (true);
            gauge_frame.set_label_align ((float)0.1, (float)0.5);
            // gauge_frame.set_halign (Gtk.Align.CENTER);
            gauge_frame.add (gauge);
            gauge_frame.set_hexpand (false);
            gauge_frame.set_vexpand (true);
            
            // query order: name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free

            data_frame.set_label_align ((float)0.04, (float)0.5);
            var data_grid = new Gtk.Grid ();
            data_grid.set_column_spacing (20);
            data_grid.set_row_spacing (10);
            data_grid.set_margin_top (20);
            data_grid.set_margin_bottom (20);
            data_grid.set_margin_start (20);
            data_grid.set_margin_end (20);
            data_grid.set_column_homogeneous (true);
            data_grid.set_row_homogeneous (false);

            var data_name = new Gtk.Label (_("Name"));
            var data_driver_version = new Gtk.Label (_("Driver version"));
            var data_memory_used = new Gtk.Label (_("Memory used"));
            var data_temp = new Gtk.Label (_("Temperature"));
            var data_fan_speed = new Gtk.Label (_("Fan speed"));
            var data_time = new Gtk.Label (_("Timestamp"));
            var data_vbios_version = new Gtk.Label (_("VBios version"));
            var data_pstate = new Gtk.Label (_("Pstate"));
            var data_utilization_gpu = new Gtk.Label (_("GPU Utilization"));
            var data_index = new Gtk.Label (_("GPU index"));

            data_name.set_xalign (float.parse ("0.0"));
            data_driver_version.set_xalign (float.parse ("0.0"));
            data_memory_used.set_xalign (float.parse ("0.0"));
            data_temp.set_xalign (float.parse ("0.0"));
            data_fan_speed.set_xalign (float.parse ("0.0"));
            data_time.set_xalign (float.parse ("0.0"));
            data_vbios_version.set_xalign (float.parse ("0.0"));
            data_pstate.set_xalign (float.parse ("0.0"));
            data_utilization_gpu.set_xalign (float.parse ("0.0"));
            data_index.set_xalign (float.parse ("0.0"));

            data_name.get_style_context().add_class("data_title");
            data_driver_version.get_style_context().add_class("data_title");
            data_memory_used.get_style_context().add_class("data_title");
            data_temp.get_style_context().add_class("data_title");
            data_fan_speed.get_style_context().add_class("data_title");
            data_time.get_style_context().add_class("data_title");
            data_vbios_version.get_style_context().add_class("data_title");
            data_pstate.get_style_context().add_class("data_title");
            data_utilization_gpu.get_style_context().add_class("data_title");
            data_index.get_style_context().add_class("data_title");

            // display order: index,name,vbios_version,pstate,driver_version,memory.used,utilization.gpu,fan.speed,temperature.gpu,timestamp
            data_grid.attach (data_index, 0, 0, 1, 1);
            data_grid.attach (data_name, 0, 1, 1, 1);
            data_grid.attach (data_vbios_version, 0, 2, 1, 1);
            data_grid.attach (data_pstate, 0, 3, 1, 1);
            data_grid.attach (data_driver_version, 0, 4, 1, 1);
            data_grid.attach (data_memory_used, 0, 5, 1, 1);
            data_grid.attach (data_utilization_gpu, 0, 6, 1, 1);
            data_grid.attach (data_fan_speed, 0, 7, 1, 1);
            data_grid.attach (data_temp, 0, 8, 1, 1);
            data_grid.attach (data_time, 0, 9, 1, 1);

            gpu_name.set_xalign (float.parse ("0.0"));
            gpu_driver_version.set_xalign (float.parse ("0.0"));
            gpu_memory_used.set_xalign (float.parse ("0.0"));
            gpu_temp.set_xalign (float.parse ("0.0"));
            gpu_fan_speed.set_xalign (float.parse ("0.0"));
            gpu_time.set_xalign (float.parse ("0.0"));
            gpu_vbios_version.set_xalign (float.parse ("0.0"));
            gpu_pstate.set_xalign (float.parse ("0.0"));
            gpu_utilization_gpu.set_xalign (float.parse ("0.0"));
            gpu_index.set_xalign (float.parse ("0.0"));

            // display order: index,name,vbios_version,pstate,driver_version,memory.used,utilization.gpu,fan.speed,temperature.gpu,timestamp
            gpu_index.get_style_context().add_class("data_value");
            gpu_name.get_style_context().add_class("data_value");
            gpu_driver_version.get_style_context().add_class("data_value");
            gpu_memory_used.get_style_context().add_class("data_value");
            gpu_temp.get_style_context().add_class("data_value");
            gpu_fan_speed.get_style_context().add_class("data_value");
            gpu_time.get_style_context().add_class("data_value");
            gpu_vbios_version.get_style_context().add_class("data_value");
            gpu_pstate.get_style_context().add_class("data_value");
            gpu_utilization_gpu.get_style_context().add_class("data_value");

            data_grid.attach (gpu_index, 1, 0, 1, 1);
            data_grid.attach (gpu_name, 1, 1, 1, 1);
            data_grid.attach (gpu_vbios_version, 1, 2, 1, 1);
            data_grid.attach (gpu_pstate, 1, 3, 1, 1);
            data_grid.attach (gpu_driver_version, 1, 4, 1, 1);
            data_grid.attach (gpu_memory_used, 1, 5, 1, 1);
            data_grid.attach (gpu_utilization_gpu, 1, 6, 1, 1);
            data_grid.attach (gpu_fan_speed, 1, 7, 1, 1);
            data_grid.attach (gpu_temp, 1, 8, 1, 1);
            data_grid.attach (gpu_time, 1, 9, 1, 1);

            data_grid.set_halign (Gtk.Align.START);

            data_frame.add (data_grid);
            data_frame.set_hexpand (true);
            data_frame.set_vexpand (true);

            
            main_grid.set_column_spacing (10);
            main_grid.set_row_spacing (10);
            main_grid.set_margin_top (10);
            main_grid.set_margin_bottom (10);
            main_grid.set_margin_start (10);
            main_grid.set_margin_end (10);
            main_grid.set_column_homogeneous (false);
            main_grid.set_row_homogeneous (true);
            main_grid.set_vexpand (true);
            main_grid.attach (data_frame, 0, 0, 1, 1);
            main_grid.attach (meter_frame, 1, 0, 1, 1);
            main_grid.attach (gauge_frame, 2, 0, 1, 1);
        }

        /**
         * init_toolbar:
         *
         * Constructor for the toolbar grid where are all the controls of the Application
         */
        private void init_toolbar () {
            Gtk.Box hbox_xconfig_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_xconfig_btn.pack_start (
                new Gtk.Image.from_icon_name ("emblem-system-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_xconfig_btn.pack_start (new Gtk.Label (_("Initialize Nvidia Xconfig")), true, true, 0);
            xconfig_btn.add (hbox_xconfig_btn);
            xconfig_btn.clicked.connect (set_config);
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
            reboot_btn.clicked.connect (reboot);

            scale.set_hexpand (true);
            scale.set_digits (0);
            scale.add_mark (0, Gtk.PositionType.TOP, "0");
            scale.add_mark (100, Gtk.PositionType.TOP, "100");
            scale.set_value (get_fan_speed());
           
            Gtk.Box hbox_refresh_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_refresh_btn.pack_start (
                new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.DND),
                true,
                true,
                0
            );
            hbox_refresh_btn.pack_start (new Gtk.Label (_("Refresh")), true, true, 0);
            refresh_btn.add (hbox_refresh_btn);
            refresh_btn.clicked.connect (refresh_smi_void);

            Gtk.Box hbox_set_speed_btn = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            hbox_set_speed_btn.pack_start (
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
        }

        /**
         * create_window_structure:
         *
         * Combine every part of the Application
         */
        private void create_window_structure () {
            main_box.set_vexpand (true);
            main_box.add (main_grid);
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
        private bool refresh_smi () { // query order: name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free
            try {
                string[] spawn_args = {"nvidia-smi", "--query-gpu=name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free", "--format=csv,noheader,nounits"};
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
                    ls_stdout.strip ();
                    var rtrn = ls_stdout.split (", ");
                    print("ls_stdout: " + ls_stdout + "\n");

                    meter.set_percent (int.parse (rtrn[4]));
                    gauge.set_value (int.parse (rtrn[1]));

                    gpu_name.set_label (rtrn[0]);
                    gpu_fan_speed.set_label (rtrn[1] + " %");
                    var now = new DateTime.now_local ();
                    gpu_time.set_label (now.format ("%x %X"));
                    gpu_driver_version.set_label (rtrn[3]);
                    gpu_temp.set_label (rtrn[4] + " °C");
                    gpu_memory_used.set_label (rtrn[5] + " Mb / " + rtrn[6] + " Mb");
                    gpu_vbios_version.set_label (rtrn[7]);
                    gpu_pstate.set_label (rtrn[8]);
                    gpu_utilization_gpu.set_label ((rtrn[9] == "[Not Supported]") ? _("Not supported") : rtrn[9] + " %");
                    gpu_index.set_label (rtrn[10]);

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
            bool second_cmd = exec_command ({"nvidia-settings", "-a", "[fan:0]/GPUTargetFanSpeed=" + val});
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
