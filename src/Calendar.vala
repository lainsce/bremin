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
            header_box.set_halign(Gtk.Align.CENTER);
            header_box.margin_bottom = 12;
            main_box.append(header_box);

            prev_button = new He.Button(null, null);
            prev_button.icon = "go-previous-symbolic";
            prev_button.is_disclosure = true;
            prev_button.clicked.connect(go_previous_month);
            header_box.append(prev_button);

            month_label = new Gtk.Label("");
            month_label.add_css_class("cb-title");
            month_label.set_hexpand(true);
            month_label.set_halign(Gtk.Align.CENTER);
            header_box.append(month_label);

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
                label.set_size_request(56, -1);
                day_labels_grid.attach(label, i, 0);
            }

            date_grid = new Gtk.Grid();
            main_box.append(date_grid);

            for (int row = 0; row < 6; row++) {
                for (int col = 0; col < 7; col++) {
                    var button = new He.Button(null, null);
                    button.set_size_request(56, 56);
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
                        button.add_css_class("session-day");
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
    }
}
