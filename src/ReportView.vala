namespace Bremin {
    public class ReportView : Gtk.Box {
        private MainWindow parent_window;
        private Gtk.Label title_label;
        private Gtk.Grid metrics_grid;
        private He.Button finish_button;
        private He.Button stats_button;
        private int session_duration;
        private int session_breaths;

        public ReportView(MainWindow parent) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 20);
            parent_window = parent;
            setup_ui();
        }

        private void setup_ui() {
            add_css_class("report-background");
            add_css_class("xxx-large-radius");
            margin_end = 18;
            margin_start = 18;
            margin_bottom = 12;

            title_label = new Gtk.Label("Breathing Report");
            title_label.add_css_class("view-title");
            title_label.set_halign(Gtk.Align.CENTER);
            title_label.set_margin_bottom(50);
            title_label.set_margin_top(20);
            append(title_label);

            metrics_grid = new Gtk.Grid();
            metrics_grid.set_column_spacing(30);
            metrics_grid.set_row_spacing(30);
            metrics_grid.set_halign(Gtk.Align.CENTER);
            metrics_grid.set_hexpand(true);
            append(metrics_grid);

            var buttons_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            buttons_box.set_halign(Gtk.Align.CENTER);
            buttons_box.set_margin_top(50);
            append(buttons_box);

            stats_button = new He.Button(null, "View Progress");
            stats_button.is_pill = true;
            stats_button.size = He.ButtonSize.MEDIUM;
            stats_button.color = He.ButtonColor.SECONDARY;
            stats_button.clicked.connect(() => {
                parent_window.report_finished(session_duration, session_breaths);
            });
            buttons_box.append(stats_button);

            finish_button = new He.Button(null, "Finish");
            finish_button.is_pill = true;
            finish_button.size = He.ButtonSize.MEDIUM;
            finish_button.clicked.connect(() => {
                parent_window.report_finished(session_duration, session_breaths);
                parent_window.return_to_setup();
            });
            buttons_box.append(finish_button);
        }

        public void show_report(int duration_minutes, int breath_count) {
            session_duration = duration_minutes;
            session_breaths = breath_count;

            // Clear previous metrics
            var child = metrics_grid.get_first_child();
            while (child != null) {
                var next = child.get_next_sibling();
                metrics_grid.remove(child);
                child = next;
            }

            // Calculate metrics
            float breaths_per_minute = 0.0f;
            if (duration_minutes > 0) {
                breaths_per_minute = (float)breath_count / (float)duration_minutes;
            }

            // Create metric cards in a 2x2 grid
            create_metric_card("Total\nBreaths", breath_count.to_string(), 0, 0);
            create_metric_card("Exercise\nDuration", "%dmin".printf(duration_minutes), 1, 0);
            create_metric_card("Breaths Per\nMinute", "%.1f".printf(breaths_per_minute), 0, 1);
            create_metric_card("Session\nComplete", "✓", 1, 1);
        }

        private void create_metric_card(string label_text, string value_text, int col, int row) {
            var card = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            card.add_css_class("metric-star");
            card.set_size_request(120, 120);
            card.set_halign(Gtk.Align.CENTER);
            card.set_valign(Gtk.Align.CENTER);

            var value_label = new Gtk.Label(value_text);
            value_label.add_css_class("metric-value");
            value_label.set_halign(Gtk.Align.CENTER);
            value_label.set_margin_top(20);
            card.append(value_label);

            var label = new Gtk.Label(label_text);
            label.add_css_class("metric-label");
            label.set_halign(Gtk.Align.CENTER);
            label.set_justify(Gtk.Justification.CENTER);
            label.set_margin_bottom(20);
            card.append(label);

            metrics_grid.attach(card, col, row);
        }
    }
}
