/*
 * meter.vala
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
    
    /**
     * 
     */
    public class Meter : Gtk.DrawingArea {

        private int value;
        private bool vertical;
        private int my_width;
        private int my_height;
        private bool my_debug;
        private int min_range;
        private int max_range;

        private Pango.Layout layout;
        
        public Meter (Gtk.Orientation orientation, int min, int max, bool scale_on_resize = false, bool debug = false) {
            if ( min > max) {
                int tmp = min;
                min = max;
                max = tmp;
            }

            min_range = min;
            max_range = max;

            value = min;

            my_debug = debug;

            if (orientation == Gtk.Orientation.VERTICAL) {
                vertical = true;
            } else {
                vertical = false;
            }

            // set_size_request (width, height);


            int width = 80;
            int height = 120;
            set_my_width (width);
            set_my_height (height);

            if (my_debug) {
                print("start size: " + (get_my_width ()).to_string () + " x " + (get_my_height ()).to_string () + "\n");
                print("debug: " + (debug).to_string () + "\n");
            }

            redraw_canvas ();

            if (scale_on_resize)
                this.configure_event.connect (on_window_configure_event);
        }

        public override bool draw (Cairo.Context cr) {
            var x0_rect1 = (double) ((double) get_my_width () / 100) * 4.5;
            var x0_rect2 = (double) ((double) get_my_width () / 100) * 52.5;
            var w_rect = (double) ((double) get_my_width () / 100) * 43;
            var h_rect = (double) ((double) get_my_height () / 100) * 3.2;
            var y0_rect = (double) ((double) get_my_height () / 100) * 4.2;

            if (!vertical) { // rotate 90°
                x0_rect1 = (double) ((double) get_my_height () / 100) * 4.5;
                x0_rect2 = (double) ((double) get_my_height () / 100) * 52.5;
                w_rect = (double) ((double) get_my_height () / 100) * 43;
                h_rect = (double) ((double) get_my_width () / 100) * 3.5;
                y0_rect = (double) ((double) get_my_width () / 100) * 4.5;
            }
            int percent = (int) (((value - min_range) * 100) / (max_range - min_range));

            var limit = (int) (20 - percent / 5);
            if (percent >= 95 && percent < 100)
                limit = 19;

            if (my_debug)
                print ("percent: " + (percent).to_string () + " - limit: " + (limit).to_string () + "\n");

            cr.save ();

            if (vertical) {
                /*
                 * Vertical
                 * start form top left corner to draw so rgb scale must start from red 
                 * for i = 1 and go green for i = 20
                 */
                for (int i = 1; i <= 20; i++) {
                    if (i > limit) {
                        cr.set_source_rgb (1.0 - (0.6 / 20) * i, 0.0 + (1.0 / 20) * i, 0);
                    } else {
                        cr.set_source_rgb (0.2, 0.4, 0);
                    }
                    cr.rectangle (x0_rect1, i * y0_rect, w_rect, h_rect);
                    cr.rectangle (x0_rect2, i * y0_rect, w_rect, h_rect);
                    if (my_debug)
                        print (
                            (x0_rect1).to_string () + " x " + (i * y0_rect).to_string () + " x " + (w_rect).to_string () + " x " + (h_rect).to_string () + " \n" +
                            (x0_rect2).to_string () + " x " + (i * y0_rect).to_string () + " x " + (w_rect).to_string () + " x " + (h_rect).to_string () + " \n"
                        );
                    cr.fill ();
                }
            } else {
                limit = (int) (percent / 5);
                /* 
                 *Horizontal
                 * start form top left corner to draw so rgb scale must start from green 
                 * for i = 1 and go red for i = 20
                 */
                for (int i = 1; i <= 20; i++) {
                    if (i <= limit) {
                        cr.set_source_rgb (0.4 + (0.6 / 20) * i, 1.0 - (1.0 / 20) * i, 0);
                    } else {
                        cr.set_source_rgb (0.2, 0.4, 0);
                    }
                    cr.rectangle (i * y0_rect, x0_rect1, h_rect, w_rect);
                    cr.rectangle (i * y0_rect, x0_rect2, h_rect, w_rect);
                    if (my_debug)
                        print (
                            (i * y0_rect).to_string () + " x " + (x0_rect1).to_string () + " x " + (h_rect).to_string () + " x " + (w_rect).to_string () + " \n" +
                            (i * y0_rect).to_string () + " x " + (x0_rect2).to_string () + " x " + (h_rect).to_string () + " x " + (w_rect).to_string () + " \n"
                        );
                    cr.fill ();
                }
            }
             if (my_debug) {
                // DEBUG draw bordercontext.set_source_rgba (1, 0, 0, 1);
                cr.set_source_rgb (0, 0, 1);
                cr.set_line_width (1);

                cr.move_to (1, 1);
                cr.line_to (1, get_my_height () - 1);
                cr.line_to (get_my_width () - 1, get_my_height () - 1);
                cr.line_to (get_my_width () - 1, 1);
                cr.line_to (1, 1);

                print ("size after redraw:" + (get_my_width ()).to_string () + " x " + (get_my_height ()).to_string () + " \n");
             }
            
            cr.stroke ();
            cr.restore ();

            // draw label
            cr.save ();
            this.layout = Pango.cairo_create_layout (cr);

            // var font_descdesc = Pango.FontDescription.from_string ("Ubuntu Mono " + (radius / 8).to_string ());
            var font_descdesc = Pango.FontDescription.from_string ("Arial 17");
            layout.set_font_description (font_descdesc);
            cr.set_source_rgb (1.0 - (0.6 / 20) * limit, 0.0 + (1.0 / 20) * limit, 0);
            // cr.set_source_rgb (0.5, 0.5, 0.5);
            int fontw, fonth;
            this.layout.get_pixel_size (out fontw, out fonth);
            layout.set_text (value.to_string () + " °C", -1);
            cr.move_to (get_my_width () / 2 - fonth * 5 / 4, get_my_height () - fonth * 5 / 4);

            Pango.cairo_update_layout (cr, this.layout);
            Pango.cairo_show_layout (cr, this.layout);
            cr.restore ();

            return false;
        }

        private int get_my_width () {
            return my_width;
        }

        private int get_my_height () {
            return my_height;
        }

        private void set_my_width (int width) {
            my_width = width;
        }

        private void set_my_height (int height) {
            my_height = height;
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
            // window.process_updates (true);
        }

        public bool fit_size (Gtk.Widget parent) {
            set_my_width (parent.get_allocated_width ());
            set_my_height (parent.get_allocated_height ());
            set_size_request (get_my_width (), get_my_height ());
            redraw_canvas ();
            return false;
        }

        public bool set_size (int width, int height) {
            set_size_request (width, height);
            redraw_canvas ();
            return false;
        }

        public void set_percent (int sel) {
            if (sel <= max_range && sel >= min_range)
                value = sel;

            if (my_debug)
                print ("value->sel: " + (value).to_string () + "\n");

            redraw_canvas ();
        }
    }
}