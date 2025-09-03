namespace Bremin {
    public class CustomCalendar : Gtk.Box {
        private GLib.DateTime current_date;
        private GLib.HashTable<string, bool> session_days;
        private He.Button prev_button;
        private He.Button next_button;
        private Gtk.Label month_label;
        private Gtk.Grid date_grid;
        private He.Button[,] date_buttons;

        public CustomCalendar() {
            current_date = new GLib.DateTime.now_local();
            session_days = new GLib.HashTable<string, bool>(str_hash, str_equal);
            date_buttons = new He.Button[6,7];
            setup_ui();
            update_calendar();
        }

        private void setup_ui() {
            margin_bottom = 12;

            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            append(main_box);

            var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            header_box.margin_bottom = 12;
            main_box.append(header_box);

            month_label = new Gtk.Label("");
            month_label.add_css_class("cb-title");
            month_label.add_css_class("month-label");
            month_label.set_hexpand(true);
            month_label.set_halign(Gtk.Align.START);
            header_box.append(month_label);

            prev_button = new He.Button(null, null);
            prev_button.icon = "go-previous-symbolic";
            prev_button.is_disclosure = true;
            prev_button.clicked.connect(go_previous_month);
            header_box.append(prev_button);

            next_button = new He.Button(null, null);
            next_button.icon = "go-next-symbolic";
            next_button.is_disclosure = true;
            next_button.clicked.connect(go_next_month);
            header_box.append(next_button);

            var day_labels_grid = new Gtk.Grid();
            day_labels_grid.set_column_homogeneous(true);
            main_box.append(day_labels_grid);

            string[] day_names = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
            for (int i = 0; i < 7; i++) {
                var label = new Gtk.Label(day_names[i]);
                label.add_css_class("caption");
                label.set_halign(Gtk.Align.CENTER);
                label.set_size_request(40, -1);
                day_labels_grid.attach(label, i, 0);
            }

            date_grid = new Gtk.Grid();
            date_grid.set_column_homogeneous(true);
            main_box.append(date_grid);

            for (int row = 0; row < 6; row++) {
                for (int col = 0; col < 7; col++) {
                    var button = new He.Button(null, null);
                    button.set_size_request(40, 40);
                    button.is_tint = true;
                    button.add_css_class ("session-button");
                    date_buttons[row, col] = button;
                    date_grid.attach(button, col, row);
                }
            }
        }

        private void go_previous_month() {
            current_date = current_date.add_months(-1);
            update_calendar();
        }

        private void go_next_month() {
            current_date = current_date.add_months(1);
            update_calendar();
        }

        private void update_calendar() {
            month_label.set_text(current_date.format("%B %Y"));

            var first_day = new GLib.DateTime.local(
                current_date.get_year(),
                current_date.get_month(),
                1, 0, 0, 0
            );

            int start_day = first_day.get_day_of_week() % 7;
            int days_in_month = first_day.add_months(1).add_days(-1).get_day_of_month();

            for (int row = 0; row < 6; row++) {
                for (int col = 0; col < 7; col++) {
                    var button = date_buttons[row, col];
                    button.set_visible(false);
                    button.remove_css_class("session-day");
                    button.set_tooltip_text("");
                }
            }

            int date = 1;
            for (int row = 0; row < 6 && date <= days_in_month; row++) {
                for (int col = (row == 0 ? start_day : 0); col < 7 && date <= days_in_month; col++) {
                    var button = date_buttons[row, col];
                    button.set_label(date.to_string());
                    button.set_visible(true);
                    button.set_sensitive(true);

                    var date_key = "%04d-%02d-%02d".printf(
                        current_date.get_year(),
                        current_date.get_month(),
                        date
                    );

                    if (session_days.contains(date_key)) {
                        var drawing_area = new Gtk.DrawingArea();
                        drawing_area.set_size_request(40,40);
                        drawing_area.set_draw_func((da, cr, w, h) => {
                            var center_x = w / 2.0;
                            var center_y = h / 2.0;
                            var radius = Math.fmin(w, h) / 2;
                            Gdk.RGBA color = {};
                            color.parse("#e8f4b8"); // Acid green color
                            Gdk.RGBA line = {};
                            line.parse("#838a5b"); // Acid green color

                            draw_flower_line(cr, center_x, center_y, radius, line);
                            draw_flower_shape(cr, center_x, center_y, radius-0.5, color);
                        });
                        var label = new Gtk.Label(date.to_string());
                        label.set_halign(Gtk.Align.CENTER);
                        label.set_valign(Gtk.Align.CENTER);
                        var overlay = new Gtk.Overlay();
                        overlay.set_child(drawing_area);
                        overlay.add_overlay(label);
                        button.set_child(overlay);
                    }

                    date++;
                }
            }
        }

        public void mark_session_date(GLib.DateTime date) {
            var date_key = date.format("%Y-%m-%d");
            session_days.set(date_key, true);

            if (date.get_year() == current_date.get_year() &&
                date.get_month() == current_date.get_month()) {
                update_calendar();
            }
        }

        public void load_session_dates(string[] dates) {
            session_days.remove_all();
            foreach (string date_str in dates) {
                session_days.set(date_str, true);
            }
            update_calendar();
        }

        private void draw_flower_shape(Cairo.Context cr, double center_x, double center_y,
                                             double radius, Gdk.RGBA color) {
            cr.save();
            cr.translate(center_x, center_y);

            cr.new_path();

            // Create flower shape with 8 pointed teardrop petals
            int petals = 8; // N, NE, E, SE, S, SW, W, NW
            for (int i = 0; i < petals; i++) {
                double angle = (2.0 * Math.PI * i) / petals;

                // Create teardrop petal shape
                double petal_length = radius;
                double petal_width = radius * 2;

                // Calculate petal tip position
                double tip_x = Math.cos(angle) * petal_length;
                double tip_y = Math.sin(angle) * petal_length;

                // Calculate base control points for petal width
                double base_width_angle1 = angle - Math.PI / 2.0;
                double base_width_angle2 = angle + Math.PI / 2.0;

                double base_x1 = Math.cos(base_width_angle1) * petal_width * 0.5;
                double base_y1 = Math.sin(base_width_angle1) * petal_width * 0.5;
                double base_x2 = Math.cos(base_width_angle2) * petal_width * 0.5;
                double base_y2 = Math.sin(base_width_angle2) * petal_width * 0.5;

                // Draw teardrop petal using curves
                if (i == 0) {
                    cr.move_to(0, 0); // Start from center
                } else {
                    cr.line_to(0, 0); // Connect to center
                }

                // Left curve of petal
                cr.curve_to(
                    base_x1 * 0.3, base_y1 * 0.3,  // Control point near center
                    tip_x * 0.7 + base_x1 * 0.3, tip_y * 0.7 + base_y1 * 0.3,  // Control point towards tip
                    tip_x, tip_y  // Petal tip
                );

                // Right curve of petal back to center
                cr.curve_to(
                    tip_x * 0.7 + base_x2 * 0.3, tip_y * 0.7 + base_y2 * 0.3,  // Control point towards tip
                    base_x2 * 0.3, base_y2 * 0.3,  // Control point near center
                    0, 0  // Back to center
                );
            }
            cr.close_path();

            // Solid color
            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.fill();

            cr.restore();
        }

        private void draw_flower_line(Cairo.Context cr, double center_x, double center_y,
                                             double radius, Gdk.RGBA color) {
            cr.save();
            cr.translate(center_x, center_y);

            cr.new_path();

            // Create flower shape with 8 pointed teardrop petals
            int petals = 8; // N, NE, E, SE, S, SW, W, NW
            for (int i = 0; i < petals; i++) {
                double angle = (2.0 * Math.PI * i) / petals;

                // Create teardrop petal shape
                double petal_length = radius;
                double petal_width = radius * 2;

                // Calculate petal tip position
                double tip_x = Math.cos(angle) * petal_length;
                double tip_y = Math.sin(angle) * petal_length;

                // Calculate base control points for petal width
                double base_width_angle1 = angle - Math.PI / 2.0;
                double base_width_angle2 = angle + Math.PI / 2.0;

                double base_x1 = Math.cos(base_width_angle1) * petal_width * 0.5;
                double base_y1 = Math.sin(base_width_angle1) * petal_width * 0.5;
                double base_x2 = Math.cos(base_width_angle2) * petal_width * 0.5;
                double base_y2 = Math.sin(base_width_angle2) * petal_width * 0.5;

                // Draw teardrop petal using curves
                if (i == 0) {
                    cr.move_to(0, 0); // Start from center
                } else {
                    cr.line_to(0, 0); // Connect to center
                }

                // Left curve of petal
                cr.curve_to(
                    base_x1 * 0.3, base_y1 * 0.3,  // Control point near center
                    tip_x * 0.7 + base_x1 * 0.3, tip_y * 0.7 + base_y1 * 0.3,  // Control point towards tip
                    tip_x, tip_y  // Petal tip
                );

                // Right curve of petal back to center
                cr.curve_to(
                    tip_x * 0.7 + base_x2 * 0.3, tip_y * 0.7 + base_y2 * 0.3,  // Control point towards tip
                    base_x2 * 0.3, base_y2 * 0.3,  // Control point near center
                    0, 0  // Back to center
                );
            }
            cr.close_path();

            // Solid color
            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.set_line_width(1.0);
            cr.stroke();

            cr.restore();
        }
    }
}
