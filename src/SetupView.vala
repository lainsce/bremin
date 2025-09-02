namespace Bremin {
    public class SetupView : Gtk.Box {
        private MainWindow parent_window;
        private He.SegmentedButton duration_selector;
        private Gtk.ToggleButton duration_5_btn;
        private Gtk.ToggleButton duration_10_btn;
        private Gtk.ToggleButton duration_15_btn;
        private He.Switch sound_switch;
        private He.Switch jitter_switch;
        private He.Button start_button;

        public SetupView(MainWindow parent) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 12);
            parent_window = parent;
            setup_ui();
        }

        private void setup_ui() {
            margin_end = 18;
            margin_start = 18;

            // Daily Sentence box
            var daily_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            daily_box.set_margin_top(10);
            daily_box.set_margin_bottom(25);
            daily_box.add_css_class("daily-sentence-box");
            daily_box.add_css_class("xxx-large-radius");
            append(daily_box);

            var daily_title = new Gtk.Label("Daily Sentence");
            daily_title.add_css_class("cb-title");
            daily_title.set_use_markup(true);
            daily_title.set_xalign(0.0f);
            daily_box.append(daily_title);

            var daily_description = new Gtk.Label(get_daily_sentence());
            daily_description.set_wrap(true);
            daily_description.set_justify(Gtk.Justification.LEFT);
            daily_description.set_xalign(0.0f);
            daily_box.append(daily_description);

            // Settings cards
            var settings_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            settings_content.add_css_class("content-list");
            append (settings_content);

            var settings_card1 = new He.Card.horizontal();
            settings_card1.title = "Duration";
            settings_content.append(settings_card1);

            var settings_card2 = new He.Card.horizontal();
            settings_card2.title = "Sound Indicators";
            settings_content.append(settings_card2);

            var settings_card3 = new He.Card.horizontal();
            settings_card3.title = "Visual Jitter";
            settings_content.append(settings_card3);

            // Duration selector
            duration_selector = new He.SegmentedButton();
            duration_selector.set_halign(Gtk.Align.CENTER);

            duration_5_btn = new Gtk.ToggleButton();
            duration_10_btn = new Gtk.ToggleButton();
            duration_15_btn = new Gtk.ToggleButton();

            // Create custom content for each button
            var btn_5_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            var btn_5_icon = new Gtk.Image();
            var btn_5_label = new Gtk.Label("5 min");
            btn_5_box.append(btn_5_icon);
            btn_5_box.append(btn_5_label);
            duration_5_btn.set_child(btn_5_box);

            var btn_10_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            var btn_10_icon = new Gtk.Image();
            var btn_10_label = new Gtk.Label("10 min");
            btn_10_box.append(btn_10_icon);
            btn_10_box.append(btn_10_label);
            duration_10_btn.set_child(btn_10_box);

            var btn_15_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            var btn_15_icon = new Gtk.Image();
            var btn_15_label = new Gtk.Label("15 min");
            btn_15_box.append(btn_15_icon);
            btn_15_box.append(btn_15_label);
            duration_15_btn.set_child(btn_15_box);

            duration_5_btn.set_group(duration_10_btn);
            duration_15_btn.set_group(duration_10_btn);

            duration_10_btn.set_active(true); // Default to 10 minutes
            update_duration_icons();

            duration_5_btn.toggled.connect(() => { if (duration_5_btn.get_active()) update_duration_icons(); });
            duration_10_btn.toggled.connect(() => { if (duration_10_btn.get_active()) update_duration_icons(); });
            duration_15_btn.toggled.connect(() => { if (duration_15_btn.get_active()) update_duration_icons(); });

            duration_selector.append(duration_5_btn);
            duration_selector.append(duration_10_btn);
            duration_selector.append(duration_15_btn);
            settings_card1.widget = duration_selector;

            // Sound setting
            sound_switch = new He.Switch();
            sound_switch.set_halign(Gtk.Align.END);
            settings_card2.widget = sound_switch;

            // Jitter setting
            jitter_switch = new He.Switch();
            jitter_switch.set_halign(Gtk.Align.END);
            settings_card3.widget = jitter_switch;

            start_button = new He.Button(null, "Start Breathing");
            start_button.is_pill = true;
            start_button.size = He.ButtonSize.MEDIUM;
            start_button.set_margin_top(24);
            start_button.clicked.connect(on_start_clicked);
            append(start_button);
        }

        private void update_duration_icons() {
            // Get the icon images from each button's child box
            var btn_5_box = duration_5_btn.get_child() as Gtk.Box;
            var btn_10_box = duration_10_btn.get_child() as Gtk.Box;
            var btn_15_box = duration_15_btn.get_child() as Gtk.Box;

            var btn_5_icon = btn_5_box?.get_first_child() as Gtk.Image;
            var btn_10_icon = btn_10_box?.get_first_child() as Gtk.Image;
            var btn_15_icon = btn_15_box?.get_first_child() as Gtk.Image;

            // Clear all icons first
            if (btn_5_icon != null) btn_5_icon.clear();
            if (btn_10_icon != null) btn_10_icon.clear();
            if (btn_15_icon != null) btn_15_icon.clear();

            // Add icon to active button
            if (duration_5_btn.get_active() && btn_5_icon != null) {
                btn_5_icon.visible = true;
                btn_5_icon.set_from_icon_name("clock-filled-symbolic");
                if (btn_10_icon != null) btn_10_icon.visible = false;
                if (btn_15_icon != null) btn_15_icon.visible = false;
            } else if (duration_10_btn.get_active() && btn_10_icon != null) {
                btn_10_icon.visible = true;
                btn_10_icon.set_from_icon_name("clock-filled-symbolic");
                if (btn_5_icon != null) btn_5_icon.visible = false;
                if (btn_15_icon != null) btn_15_icon.visible = false;
            } else if (duration_15_btn.get_active() && btn_15_icon != null) {
                btn_15_icon.visible = true;
                btn_15_icon.set_from_icon_name("clock-filled-symbolic");
                if (btn_10_icon != null) btn_10_icon.visible = false;
                if (btn_5_icon != null) btn_5_icon.visible = false;
            }
        }

        private void on_start_clicked() {
            int duration = 10; // Default
            if (duration_5_btn.get_active()) {
                duration = 5;
            } else if (duration_15_btn.get_active()) {
                duration = 15;
            }

            bool sounds = sound_switch.iswitch.get_active();
            bool jitter = jitter_switch.iswitch.get_active();

            parent_window.start_breathing_session(duration, sounds, jitter);
        }
    }
}
