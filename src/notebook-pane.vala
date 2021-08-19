/*
 * notebook-pane.vala
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

    public class NotebookPane : Gtk.Box {

        private Gtk.Grid main_grid;
        // graph widgets
        private GpuFanControl.Meter meter;
        private GpuFanControl.Gauge gauge;
        private Gtk.Frame meter_frame;
        private Gtk.Frame gauge_frame;
        private Gtk.Frame data_frame;
        // data panel
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
        private Gtk.Label gpu_fan_rpm;
        private Gtk.Label gpu_graphic_clock;
        private Gtk.Label gpu_processor_clock;
        // set speed toolbar
        private Gtk.Grid toolbar;
        private Gtk.Button refresh_btn;
        private Gtk.Button set_speed_btn;
        private Gtk.Scale scale;

        private GpuFanControl.Application app;
        private int id;

        public NotebookPane (GpuFanControl.Application application, int gpu_id) {
            app = application;
            id = gpu_id;

            this.set_orientation (Gtk.Orientation.VERTICAL);

            this.init_widgets ();
            this.init_main_panel ();
            this.init_toolbar ();


            this.add (main_grid);
            this.add (toolbar);
        }

        /**
         * init_widgets:
         *
         * Initiaize widgets objects and vars
         */
        private void init_widgets () {
            main_grid = new Gtk.Grid ();
            data_frame = new Gtk.Frame (_("Gpu data"));
            meter_frame = new Gtk.Frame (_("Temperature"));
            gauge_frame = new Gtk.Frame (_("Fan speed"));
            gpu_name = new Gtk.Label ("");
            gpu_fan_speed = new Gtk.Label ("");
            gpu_fan_rpm = new Gtk.Label ("");
            gpu_driver_version = new Gtk.Label ("");
            gpu_temp = new Gtk.Label ("");
            gpu_time = new Gtk.Label ("");
            gpu_memory_used = new Gtk.Label ("");
            gpu_vbios_version = new Gtk.Label ("");
            gpu_pstate = new Gtk.Label ("");
            gpu_utilization_gpu = new Gtk.Label ("");
            gpu_index = new Gtk.Label ("");
            gpu_graphic_clock = new Gtk.Label ("");
            gpu_processor_clock = new Gtk.Label ("");
            refresh_btn = new Gtk.Button ();
            set_speed_btn = new Gtk.Button ();
            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);

            meter = new GpuFanControl.Meter (Gtk.Orientation.VERTICAL, 0, 120, true, false);
            gauge = new GpuFanControl.Gauge (0, 100, GpuFanControl.Gauge.Position.LEFT, true);

            // containers
            toolbar = new Gtk.Grid ();

            meter.fit_size (meter_frame);
            gauge.fit_size (gauge_frame);

            if (!refresh_smi ()) {
                app.show_dialog ("error", _("Error"), app.get_error_msg ());
                app.set_error_msg ("");
            };

            // timer for continuosly refreh main panel data
            app.add_timeout_item (Timeout.add_seconds_full (GLib.Priority.DEFAULT, 5, refresh_smi));
        }

        /**
         * init_main_panel:
         *
         * Constructor for the scrollable label in which display nvidia-smi results
         */
        private void init_main_panel () {
            meter.set_size (140, 240);
            meter.set_halign (Gtk.Align.CENTER);
            meter.set_hexpand (false);
            meter.set_vexpand (true);
            gauge.set_size (140, 240);
            gauge.set_halign (Gtk.Align.CENTER);
            gauge.set_hexpand (false);
            gauge.set_vexpand (true);
            gauge.set_margin_top (10);
            gauge.set_margin_bottom (0);
            gauge.set_margin_start (5);
            gauge.set_margin_end (5);
            refresh_smi ();

            // meter_frame.set_halign (Gtk.Align.CENTER);
            meter_frame.add (meter);
            meter_frame.set_hexpand (false);
            meter_frame.set_vexpand (true);
            // gauge_frame.set_halign (Gtk.Align.CENTER);
            gauge_frame.add (gauge);
            gauge_frame.set_hexpand (false);
            gauge_frame.set_vexpand (true);

            // query order: name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free

            var data_grid = new Gtk.Grid ();
            data_grid.set_column_spacing (30);
            data_grid.set_row_spacing (10);
            data_grid.set_margin_top (10);
            data_grid.set_margin_bottom (10);
            data_grid.set_margin_start (20);
            data_grid.set_margin_end (20);
            data_grid.set_column_homogeneous (true);
            data_grid.set_row_homogeneous (true);

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
            var data_fan_rpm = new Gtk.Label (_("Fan speed") + " (rpm)");
            var data_graphic_clock = new Gtk.Label (_("Graphics Clock"));
            var data_processor_clock = new Gtk.Label (_("Processor Clock"));

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
            data_fan_rpm.set_xalign (float.parse ("0.0"));
            data_graphic_clock.set_xalign (float.parse ("0.0"));
            data_processor_clock.set_xalign (float.parse ("0.0"));

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
            data_fan_rpm.get_style_context().add_class("data_title");
            data_graphic_clock.get_style_context().add_class("data_title");
            data_processor_clock.get_style_context().add_class("data_title");

            // display order: index,name,vbios_version,pstate,driver_version,memory.used,utilization.gpu,fan.speed,temperature.gpu,timestamp
            data_grid.attach (data_index, 0, 0, 1, 1);
            data_grid.attach (data_name, 0, 1, 1, 1);
            data_grid.attach (data_vbios_version, 0, 2, 1, 1);
            data_grid.attach (data_pstate, 0, 3, 1, 1);
            data_grid.attach (data_driver_version, 0, 4, 1, 1);
            data_grid.attach (data_graphic_clock, 0, 5, 1, 1);
            data_grid.attach (data_processor_clock, 0, 6, 1, 1);
            data_grid.attach (data_memory_used, 0, 7, 1, 1);
            data_grid.attach (data_utilization_gpu, 0, 8, 1, 1);
            data_grid.attach (data_fan_speed, 0, 9, 1, 1);
            data_grid.attach (data_fan_rpm, 0, 10, 1, 1);
            data_grid.attach (data_temp, 0, 11, 1, 1);
            data_grid.attach (data_time, 0, 12, 1, 1);

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
            gpu_fan_rpm.set_xalign (float.parse ("0.0"));
            gpu_graphic_clock.set_xalign (float.parse ("0.0"));
            gpu_processor_clock.set_xalign (float.parse ("0.0"));

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
            gpu_fan_rpm.get_style_context().add_class("data_value");
            gpu_graphic_clock.get_style_context().add_class("data_value");
            gpu_processor_clock.get_style_context().add_class("data_value");

            data_grid.attach (gpu_index, 1, 0, 1, 1);
            data_grid.attach (gpu_name, 1, 1, 1, 1);
            data_grid.attach (gpu_vbios_version, 1, 2, 1, 1);
            data_grid.attach (gpu_pstate, 1, 3, 1, 1);
            data_grid.attach (gpu_driver_version, 1, 4, 1, 1);
            data_grid.attach (gpu_graphic_clock, 1, 5, 1, 1);
            data_grid.attach (gpu_processor_clock, 1, 6, 1, 1);
            data_grid.attach (gpu_memory_used, 1, 7, 1, 1);
            data_grid.attach (gpu_utilization_gpu, 1, 8, 1, 1);
            data_grid.attach (gpu_fan_speed, 1, 9, 1, 1);
            data_grid.attach (gpu_fan_rpm, 1, 10, 1, 1);
            data_grid.attach (gpu_temp, 1, 11, 1, 1);
            data_grid.attach (gpu_time, 1, 12, 1, 1);

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

            scale.set_hexpand (true);
            scale.set_digits (0);
            scale.add_mark (0, Gtk.PositionType.TOP, "0");
            scale.add_mark (100, Gtk.PositionType.TOP, "100");
            scale.set_value (get_fan_speed());

            var grid_set_speed = new Gtk.Grid ();
            grid_set_speed.set_column_spacing (15);
            grid_set_speed.set_row_spacing (10);
            grid_set_speed.set_margin_top (10);
            grid_set_speed.set_margin_bottom (10);
            grid_set_speed.set_margin_start (10);
            grid_set_speed.set_margin_end (10);
            grid_set_speed.set_column_homogeneous (true);
            grid_set_speed.set_row_homogeneous (true);
            grid_set_speed.attach (scale, 0, 0, 4, 1);
            grid_set_speed.attach (refresh_btn, 0, 1, 1, 1);
            grid_set_speed.attach (set_speed_btn, 3, 1, 1, 1);
            var frame_set_speed = new Gtk.Frame (_("Set fan speed"));
            frame_set_speed.add (grid_set_speed);

            toolbar.set_column_spacing (10);
            toolbar.set_row_spacing (10);
            toolbar.set_margin_top (10);
            toolbar.set_margin_bottom (10);
            toolbar.set_margin_start (10);
            toolbar.set_margin_end (10);
            toolbar.set_column_homogeneous (true);
            toolbar.set_row_homogeneous (true);
            toolbar.attach (frame_set_speed, 0, 0, 1, 1);
        }

        /**
         * get_nvidia_settings:
         *
         * Fetch some data querying nvidia-settings
         *
         * @return a #string containing fetched data
         */
        private string get_nvidia_settings () {
            string gpu = "[gpu:" + id.to_string () + "]";
            string fan = "[fan:" + id.to_string () + "]";
            try {
                string[] spawn_args = {"nvidia-settings", "-d", "-t", "-q", gpu +"/GPUCurrentClockFreqs", "-q", gpu +"/GPUCurrentProcessorClockFreqs", "-q", fan + "/GPUCurrentFanSpeedRPM", "-q", gpu +"/GPUUtilization"};
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
                    return ls_stdout;
                } else if (ls_stderr != null) {
		            print ("stderr:\n");
                    print (ls_stderr + "\n");
                    return "error";
                }

                return "";
            } catch (SpawnError e) {
                print (e.message);
                return "error";
            }
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
                string[] spawn_args = {"nvidia-smi", "-i", id.to_string (), "--query-gpu=name,fan.speed,timestamp,driver_version,temperature.gpu,memory.used,memory.total,vbios_version,pstate,utilization.gpu,index,memory.free", "--format=csv,noheader,nounits"};
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
                    var nvset = get_nvidia_settings ().split ("\n");
                    // print (int.parse(nvset[0]).to_string () + "\n"); // GPUCurrentClockFreqs
                    // print (int.parse(nvset[1]).to_string () + "\n"); //GPUCurrentProcessorClockFreqs
                    // print (int.parse(nvset[2]).to_string () + "\n"); // PUCurrentFanSpeedRPM
                    var utilization = nvset[3].split (", "); // GPUUtilization
                    // print ("utilization: " + utilization[0].split("=")[1] + "\n"); // GPUUtilization - graphics

                    ls_stdout.strip ();
                    var rtrn = ls_stdout.split (", ");
                    // print("ls_stdout: " + ls_stdout + "\n");

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
                    gpu_utilization_gpu.set_label (utilization[0].split("=")[1] + " %");
                    gpu_index.set_label (rtrn[10]);
                    gpu_fan_rpm.set_label (int.parse(nvset[2]).to_string ());
                    gpu_graphic_clock.set_label (int.parse(nvset[0]).to_string () + " Mhz");
                    gpu_processor_clock.set_label (int.parse(nvset[1]).to_string () + " Mhz");

                    return true;
                } else if (ls_stderr != null) {
		            print ("stderr:\n" + ls_stderr + "\n");
                    app.set_error_msg (ls_stderr);
                    return false;
                }
                return true;

            } catch (SpawnError e) {
                print (e.message);
                app.set_error_msg (e.message);
                return false;
            }
        }

        /**
         * Dummy function for the execution of refresh_smi in a context
         * that doesn't need a return value
         */
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
                string[] spawn_args = {"nvidia-smi", "-i", id.to_string (), "--query-gpu=fan.speed", "--format=csv,noheader,nounits"};
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
                    print (ls_stderr + "\n");
                    return 1;
                }

                return 0;

            } catch (SpawnError e) {
                print (e.message);
                return 1;
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
            string gpu = "[gpu:" + id.to_string () + "]";
            string fan = "[fan:" + id.to_string () + "]";
            string val = ((int) scale.get_value ()).to_string ();
            // set the gpu for over clock
            bool first_cmd = app.exec_command ({"nvidia-settings", "-a", gpu + "/GPUFanControlState=1"});
            // command to set the speed
            bool second_cmd = app.exec_command ({"nvidia-settings", "-a", fan + "/GPUTargetFanSpeed=" + val});
            if (first_cmd && second_cmd) {
                app.show_dialog ("info", _("Info"), _("Fan Speed Set To ") + val);
            } else {
                app.show_dialog ("error", _("Error"), app.get_error_msg ());
                app.set_error_msg ("");
            }
            if (!refresh_smi ()) {
                app.show_dialog ("error", _("Error"), app.get_error_msg ());
                app.set_error_msg ("");
            };
        }
    }
 }
