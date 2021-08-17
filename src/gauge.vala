/*
 * gauge.vala
 * 
 * Copyright 2021 Nicola tudino <nicola.tudino@gmail.com>
 * 
 * This file is part of GPUFanControl.
 *
 * GPUFanControl is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * GPUFanControl is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GPUFanControl.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

namespace GpuFanControl {

    public class Gauge : Gtk.DrawingArea {

        public int blocks  = 18;
	    
        private double radius;
        private double arc_width;
        private double block_radius;
        private double value;
        private Position pos;

        private Pango.Layout layout;

        private double my_width;
        private double my_height;
        private double min_range;
        private double max_range;

        public Gauge (double min, double max, Position position = Position.BOTTOM, bool scale_on_resize = true) {
            if ( min > max) {
                double tmp = min;
                min = max;
                max = tmp;
            }
            min_range = min;
            max_range = max;
            value = min;
            pos = position;

            double width = 300;
            double height = 300;
            set_my_width (width);
            set_my_height (height);

            redraw_canvas ();

            if (scale_on_resize)
                this.configure_event.connect (on_window_configure_event);
        }

        public enum Position {
            TOP,
            BOTTOM,
            LEFT,
            RIGHT
        }  

        private double get_my_width () {
            return my_width;
        }

        private double get_my_height () {
            return my_height;
        }

        private void set_my_width (double width) {
            my_width = width;
        }

        private void set_my_height (double height) {
            my_height = height;
        }

        public bool fit_size (Gtk.Widget parent) {
            set_my_width (parent.get_allocated_width ());
            set_my_height (parent.get_allocated_height ());
            set_size_request ((int)get_my_width (), (int)get_my_height ());
            redraw_canvas ();
            return false;
        }

        public bool set_size (int width, int height) {
            set_size_request (width, height);
            redraw_canvas ();
            return false;
        }

        private bool on_window_configure_event (Gtk.Widget sender, Gdk.EventConfigure event) {
            set_my_width (event.width);
            set_my_height (event.height);
            redraw_canvas ();
            return true;
        }

        private void redraw_canvas () {
            var window = get_window ();
            if (null == window) {
                return;
            }

            var region = window.get_clip_region ();
            // redraw the cairo canvas completely by exposing it
            window.invalidate_region (region, true);
        }

        public void set_value (int sel) {
            if (sel <= max_range && sel >= min_range)
                value = sel;

            redraw_canvas ();
        }

        public override bool draw (Cairo.Context cr) {
            calc_radius (get_my_width (), get_my_height ());
            
            cr.save ();

            switch (pos) {
                case TOP:
                    cr.translate (get_my_width () / 2, 0);
	                cr.scale (-1, 1);
                    break;
                case BOTTOM:
                    cr.translate (get_my_width () / 2, get_my_height ());
                    cr.rotate (Math.PI);
                    break;
                case LEFT:
                    cr.translate (0, get_my_height () / 2);
                    cr.rotate (Math.PI / 2);
	                cr.scale (1, -1);
                    break;
                case RIGHT:
                    cr.translate (get_my_width (), get_my_height () / 2);
                    cr.rotate (Math.PI / 2);
                    break;
            }

            int percent = (int) (((value - min_range) * 100) / (max_range - min_range));

            var limit = (int)((double)((percent * blocks) / 100));
            // print ("percent / 100: " + ((double)((percent * blocks) / 100)).to_string () + "\n");
            // limit = 10;
            if (percent >= 95 && percent < 100)
                limit = (int)blocks - 1;
            
            // 2° of interspace between blocks
            double angle = (Math.PI / 180) * ((180 - (2 * blocks) - 1) / blocks);

            cr.set_line_width (arc_width);

            for (int i = 0; i < blocks; i++) {
                double start_angle = (i * (Math.PI / blocks)) + (2 * (Math.PI / 180));
                double end_angle = start_angle + angle;
                if (i + 1 <= limit) {
                    cr.set_source_rgb (0.4 + (0.6 / blocks) * i, 1.0 - (1.0 / blocks) * i, 0);
                } else {
                    cr.set_source_rgb (0.2, 0.4, 0);
                }
                cr.arc (0, 0, block_radius, start_angle, end_angle);
                cr.stroke ();
            }

            cr.restore ();

            // draw labels
            cr.save ();

            this.layout = Pango.cairo_create_layout (cr);

            // var font_descdesc = Pango.FontDescription.from_string ("Ubuntu Mono " + (radius / 8).to_string ());
            var font_descdesc = Pango.FontDescription.from_string ("Arial " + (radius / 8).to_string ());
            layout.set_font_description (font_descdesc);
            cr.set_source_rgb (0.4 + (0.6 / blocks) * limit, 1.0 - (1.0 / blocks) * limit, 0);
            // cr.set_source_rgb (0.5, 0.5, 0.5);
            int fontw, fonth;
            this.layout.get_pixel_size (out fontw, out fonth);

            var mark_labels = new string[] {
                min_range.to_string (),
                max_range.to_string (),
                value.to_string () + " %",
            };
            double[,] pos_x = {
                { // TOP
                    (get_my_width () / 2) - radius + (2 * arc_width),
                    (get_my_width () / 2) + radius - (2 * arc_width) - fonth,
                    (get_my_width () / 2) - fonth
                },
                { // BOTTOM
                    (get_my_width () / 2) - radius + (2 * arc_width),
                    (get_my_width () / 2) + radius - (2 * arc_width) - fonth,
                    (get_my_width () / 2) - fonth
                },
                { // LEFT
                    0,
                    0,
                    fonth
                },
                { // RIGHT
                    get_my_width () - radius * 2 / 10,
                    get_my_width () - radius * 2 / 10,
                    get_my_width () - radius / 2,
                }
            };
            double[,] pos_y = {
                { // TOP
                    0,
                    0,
                    radius / 2,
                },
                { // BOTTOM
                    get_my_height () - fonth,
                    get_my_height () - fonth,
                    get_my_height () - radius / 2,
                },
                { // LEFT
                    (get_my_height () / 2) + radius - (2 * arc_width) - fonth,
                    (get_my_height () / 2) - radius + (2 * arc_width),
                    (get_my_height () / 2) - fonth / 2,
                },
                { // RIGHT
                    (get_my_height () / 2) - radius + (2 * arc_width),
                    (get_my_height () / 2) + radius - (2 * arc_width) - fonth,
                    (get_my_height () / 2) - fonth / 2,
                }
            };
            for (var i = 0; i < mark_labels.length; i++) {
                if (i == 2) {
                    layout.set_text (mark_labels[i], -1);
                    switch (pos) {
                        case TOP:
                                cr.move_to (pos_x[0, i], pos_y[0, i]);
                            break;
                        case BOTTOM:
                                cr.move_to (pos_x[1, i], pos_y[1, i]);
                            break;
                        case LEFT:
                                cr.move_to (pos_x[2, i], pos_y[2, i]);
                            break;
                        case RIGHT:
                                cr.move_to (pos_x[3, i], pos_y[3, i]);
                            break;
                    }
                }

                Pango.cairo_update_layout (cr, this.layout);
                Pango.cairo_show_layout (cr, this.layout);
            }
            cr.restore ();
 
            return false;
        }

        private void calc_radius (double width, double height) {
            switch (pos) {
                case TOP:
                case BOTTOM:
                    if ((width / 2) >= height) {
                        radius = height;
                    } else {
                        radius = (width / 2);
                    }
                    break;
                case LEFT:
                case RIGHT:
                    if (width >= (height / 2)) {
                        radius = height / 2;
                    } else {
                        radius = width;
                    }
                    break;
            }
            arc_width = radius / 8;
            block_radius = radius * 15 / 16;
        }
    }
}