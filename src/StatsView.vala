namespace Bremin {
    public class StatsView : Gtk.Box {
        private Gtk.Label days_label;
        private Gtk.Label breaths_label;
        private Gtk.Label minutes_label;
        private He.ProgressBar exp_bar;
        private Gtk.Label exp_label;
        private Gtk.Label exp_label_progress;
        private CustomCalendar custom_calendar;
        private GLib.KeyFile data_file;
        private string data_path;
        private int total_days = 0;
        private int total_breaths = 0;
        private int total_minutes = 0;

        public StatsView() {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 12);
            setup_data_storage();
            setup_ui();
            load_data();
        }

        private void setup_data_storage() {
            var config_dir = GLib.Environment.get_user_config_dir();
            var app_config_dir = GLib.Path.build_filename(config_dir, "bremin");

            try {
                var dir = GLib.File.new_for_path(app_config_dir);
                if (!dir.query_exists()) {
                    dir.make_directory_with_parents();
                }

                data_path = GLib.Path.build_filename(app_config_dir, "sessions.conf");
                data_file = new GLib.KeyFile();

                if (GLib.FileUtils.test(data_path, GLib.FileTest.EXISTS)) {
                    data_file.load_from_file(data_path, GLib.KeyFileFlags.NONE);
                }
            } catch (Error e) {
                warning("Failed to setup data storage: %s", e.message);
                data_file = new GLib.KeyFile();
            }
        }

        private void setup_ui() {
            margin_end = 18;
            margin_start = 18;

            var stats_grid = new Gtk.Grid();
            stats_grid.set_column_spacing(40);
            stats_grid.set_row_spacing(10);
            stats_grid.set_halign(Gtk.Align.CENTER);
            stats_grid.set_margin_bottom(24);
            append(stats_grid);

            var days_title = new Gtk.Label("Days");
            stats_grid.attach(days_title, 0, 1);

            days_label = new Gtk.Label("0");
            days_label.add_css_class("display");
            stats_grid.attach(days_label, 0, 0);

            var breaths_title = new Gtk.Label("Breaths");
            stats_grid.attach(breaths_title, 1, 1);

            breaths_label = new Gtk.Label("0");
            breaths_label.add_css_class("display");
            stats_grid.attach(breaths_label, 1, 0);

            var minutes_title = new Gtk.Label("Minutes");
            stats_grid.attach(minutes_title, 2, 1);

            minutes_label = new Gtk.Label("0");
            minutes_label.add_css_class("display");
            stats_grid.attach(minutes_label, 2, 0);

            var exp_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            exp_box.set_margin_bottom(12);
            exp_box.set_margin_start(12);
            exp_box.set_margin_end(12);
            append(exp_box);

            var exp_box_labels = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            exp_box_labels.hexpand = true;
            exp_box.append(exp_box_labels);

            exp_label = new Gtk.Label("Level 1");
            exp_label.set_halign(Gtk.Align.START);
            exp_label.hexpand = true;
            exp_box_labels.append(exp_label);

            exp_label_progress = new Gtk.Label("0/100");
            exp_label_progress.set_halign(Gtk.Align.END);
            exp_box_labels.append(exp_label_progress);

            exp_bar = new He.ProgressBar();
            exp_bar.set_hexpand(true);
            exp_box.append(exp_bar);

            custom_calendar = new CustomCalendar();
            custom_calendar.set_halign(Gtk.Align.CENTER);
            custom_calendar.set_valign(Gtk.Align.START);
            append(custom_calendar);
        }

        public void add_session_data(int minutes, int breaths) {
            var now = new GLib.DateTime.now_local();
            string date_key = now.format("%Y-%m-%d");

            try {
                bool group_exists = data_file.has_group("sessions");
                bool is_new_day = true;
                int existing_minutes = 0;
                int existing_breaths = 0;

                // Check if this day already has data
                if (group_exists && data_file.has_key("sessions", date_key)) {
                    is_new_day = false;
                    string existing_data = data_file.get_string("sessions", date_key);
                    string[] parts = existing_data.split(",");
                    if (parts.length >= 2) {
                        existing_minutes = int.parse(parts[0]);
                        existing_breaths = int.parse(parts[1]);
                    }
                }

                // Calculate new totals for this day
                int new_day_minutes = existing_minutes + minutes;
                int new_day_breaths = existing_breaths + breaths;

                // Update running totals (only add the new session data)
                total_minutes += minutes;
                total_breaths += breaths;

                if (is_new_day) {
                    total_days++;
                }

                // Save updated day data
                data_file.set_string("sessions", date_key, "%d,%d".printf(new_day_minutes, new_day_breaths));
                data_file.save_to_file(data_path);

                update_display();
                custom_calendar.mark_session_date(now);

            } catch (Error e) {
                warning("Failed to save session data: %s", e.message);
            }
        }

        private void load_data() {
            total_days = 0;
            total_minutes = 0;
            total_breaths = 0;

            try {
                if (!data_file.has_group("sessions")) {
                    update_display();
                    return;
                }

                string[] keys = data_file.get_keys("sessions");
                custom_calendar.load_session_dates(keys);

                foreach (string key in keys) {
                    total_days++;
                    string data = data_file.get_string("sessions", key);
                    string[] parts = data.split(",");
                    if (parts.length >= 2) {
                        int day_minutes = int.parse(parts[0]);
                        int day_breaths = int.parse(parts[1]);
                        total_minutes += day_minutes;
                        total_breaths += day_breaths;
                    }
                }
            } catch (Error e) {
                warning("Failed to load session data: %s", e.message);
            }

            update_display();
        }

        private void update_display() {
            days_label.set_text(total_days.to_string());
            breaths_label.set_text(total_breaths.to_string());
            minutes_label.set_text(total_minutes.to_string());

            int level = 1 + total_minutes / 100;
            int progress_in_level = total_minutes % 100;
            double progress_fraction = progress_in_level / 100.0;

            exp_label.set_text("Level %d".printf(level));
            exp_label_progress.set_text("%d/100".printf(progress_in_level));
            exp_bar.progress = progress_fraction;
        }
    }
}
