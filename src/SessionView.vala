namespace Bremin {
    public class SessionView : Gtk.Box {
        private Gtk.DrawingArea breathing_area;
        private He.Button pause_button;
        private He.Button stop_button;
        private Gtk.Label time_label;
        private Gtk.Label breath_instruction_label;
        private Gtk.Image breath_instruction_icon;
        private Gtk.Image breath_instruction_icon2;
        private uint timeout_id = 0;
        private uint animation_id = 0;
        private bool is_paused = false;
        private bool is_running = false;
        private int total_seconds;
        private int elapsed_seconds = 0;
        private double breath_phase = 0.0;
        private bool sounds_enabled;
        private bool jitter_enabled;
        private int breath_count = 0;
        private int64 session_start_time = 0;

        public SessionView() {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 6);
            setup_ui();
        }

        private void setup_ui() {
            margin_end = 18;
            margin_start = 18;
            margin_bottom = 12;
            add_css_class("surface-container-bg-color");
            add_css_class("xxx-large-radius");

            time_label = new Gtk.Label("");
            time_label.add_css_class("big-display");
            time_label.margin_top = 50;
            append(time_label);

            breathing_area = new Gtk.DrawingArea();
            breathing_area.set_size_request(250, 250);
            breathing_area.set_hexpand(false);
            breathing_area.set_vexpand(false);
            breathing_area.set_halign(Gtk.Align.CENTER);
            breathing_area.set_valign(Gtk.Align.CENTER);
            breathing_area.set_draw_func(draw_breathing_flower);
            append(breathing_area);

            breath_instruction_icon = new Gtk.Image();
            breath_instruction_icon2 = new Gtk.Image();

            breath_instruction_label = new Gtk.Label("Breathe");
            breath_instruction_label.add_css_class("view-title");
            breath_instruction_label.set_use_markup(true);
            breath_instruction_label.set_justify(Gtk.Justification.CENTER);
            breath_instruction_label.set_margin_bottom(12);

            var breath_instruction_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            breath_instruction_box.set_halign(Gtk.Align.CENTER);
            breath_instruction_box.append(breath_instruction_icon);
            breath_instruction_box.append(breath_instruction_label);
            breath_instruction_box.append(breath_instruction_icon2);

            append(breath_instruction_box);

            var controls_box = new He.GroupedButton();
            controls_box.size = He.GroupedButtonSize.SMALL;
            controls_box.set_halign(Gtk.Align.CENTER);
            append(controls_box);

            pause_button = new He.Button("media-playback-pause-symbolic", null);
            pause_button.is_pill = true;
            pause_button.width = He.ButtonWidth.WIDE;
            pause_button.clicked.connect(toggle_pause);
            controls_box.add_widget(pause_button);

            stop_button = new He.Button(null, null);
            stop_button.icon = "media-playback-stop-symbolic";
            stop_button.is_pill = true;
            stop_button.width = He.ButtonWidth.NARROW;
            stop_button.color = He.ButtonColor.SECONDARY;
            stop_button.clicked.connect(stop_session);
            controls_box.add_widget(stop_button);
        }

        public void start_session(int duration_minutes, bool sounds, bool jitter) {
            total_seconds = duration_minutes * 60;
            elapsed_seconds = 0;
            breath_phase = 0.0;
            sounds_enabled = sounds;
            jitter_enabled = jitter;
            is_running = true;
            is_paused = false;
            breath_count = 0;
            session_start_time = GLib.get_monotonic_time();

            update_time_display();
            pause_button.set_icon_name("media-playback-pause-symbolic");

            timeout_id = GLib.Timeout.add(1000, update_timer);
            animation_id = GLib.Timeout.add(50, update_animation);
        }

        public void stop_session() {
            if (timeout_id != 0) {
                GLib.Source.remove(timeout_id);
                timeout_id = 0;
            }
            if (animation_id != 0) {
                GLib.Source.remove(animation_id);
                animation_id = 0;
            }
            is_running = false;
            is_paused = false;

            var window = get_root() as MainWindow;
            window?.return_to_setup();
        }

        private void toggle_pause() {
            if (!is_running) return;

            is_paused = !is_paused;

            if (is_paused) {
                pause_button.set_icon_name("media-playback-start-symbolic");
                if (timeout_id != 0) {
                    GLib.Source.remove(timeout_id);
                    timeout_id = 0;
                }
                if (animation_id != 0) {
                    GLib.Source.remove(animation_id);
                    animation_id = 0;
                }
            } else {
                pause_button.set_icon_name("media-playback-pause-symbolic");
                timeout_id = GLib.Timeout.add(1000, update_timer);
                animation_id = GLib.Timeout.add(50, update_animation);
            }
        }

        private bool update_timer() {
            if (is_paused) return false;

            elapsed_seconds++;
            update_time_display();

            if (elapsed_seconds >= total_seconds) {
                complete_session();
                return false;
            }

            return true;
        }

        private bool update_animation() {
            if (is_paused) return false;

            breath_phase += 0.002;
            if (breath_phase >= 1.0) {
                breath_phase = 0.0;
                breath_count++;
            }

            int phase_second;
            string instruction;
            string icon;

            if (breath_phase < 0.25) {
                // Inhale phase (0-0.25)
                double phase_progress = breath_phase * 4.0; // 0.0 to 1.0
                phase_second = 5 - (int)Math.floor(phase_progress * 5.0);
                instruction = "Inhale";
                icon = "pan-up-symbolic";
            } else if (breath_phase < 0.5) {
                // Hold inhaled phase (0.25-0.5)
                double phase_progress = (breath_phase - 0.25) * 4.0;
                phase_second = 5 - (int)Math.floor(phase_progress * 5.0);
                instruction = "Hold";
                icon = "media-playback-pause-symbolic";
            } else if (breath_phase < 0.75) {
                // Exhale phase (0.5-0.75)
                double phase_progress = (breath_phase - 0.5) * 4.0;
                phase_second = 5 - (int)Math.floor(phase_progress * 5.0);
                instruction = "Exhale";
                icon = "pan-down-symbolic";
            } else {
                // Hold exhaled phase (0.75-1.0)
                double phase_progress = (breath_phase - 0.75) * 4.0;
                phase_second = 5 - (int)Math.floor(phase_progress * 5.0);
                instruction = "Hold";
                icon = "media-playback-pause-symbolic";
            }

            if (phase_second < 1) phase_second = 1;
            if (phase_second > 5) phase_second = 5;

            string instruction_display = "%d\n%s".printf(phase_second, instruction);
            breath_instruction_icon.set_from_icon_name(icon);
            breath_instruction_icon2.set_from_icon_name(icon);
            breath_instruction_label.set_text(instruction_display);

            breathing_area.queue_draw();
            return true;
        }

        private void update_time_display() {
            int remaining = total_seconds - elapsed_seconds;
            int minutes = remaining / 60;
            int seconds = remaining % 60;
            time_label.set_text("%02d:%02d".printf(minutes, seconds));
        }

        private void complete_session() {
            if (timeout_id != 0) {
                GLib.Source.remove(timeout_id);
                timeout_id = 0;
            }
            if (animation_id != 0) {
                GLib.Source.remove(animation_id);
                animation_id = 0;
            }
            is_running = false;

            var window = get_root() as MainWindow;
            window?.session_completed(total_seconds / 60, breath_count);
        }

        private void draw_breathing_flower(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            double center_x = width / 2.0;
            double center_y = height / 2.0;

            double base_size = Math.fmin(width, height) / 2.5;
            double breath_multiplier;

            if (breath_phase < 0.25) {
                breath_multiplier = breath_phase * 4.0;
            } else if (breath_phase < 0.5) {
                breath_multiplier = 1.0;
            } else if (breath_phase < 0.75) {
                breath_multiplier = 1.0 - ((breath_phase - 0.5) * 4.0);
            } else {
                breath_multiplier = 0.0;
            }

            double petal_size = base_size * (0.6 + 0.4 * breath_multiplier);

            double spiral_time = elapsed_seconds * 0.1;

            Gdk.RGBA petal_color;
            if (breath_phase < 0.5) {
                petal_color = {0.5f, 0.8f, 0.0f, 0.9f};
            } else {
                petal_color = {0.1f, 0.3f, 0.9f, 0.9f};
            }

            for (int i = 0; i < 6; i++) {
                double base_angle = (i * Math.PI) / 3.0;

                double spiral_offset = 0.0;
                if (jitter_enabled && is_running && !is_paused) {
                    double petal_phase = spiral_time + (i * 0.3);
                    spiral_offset = Math.sin(petal_phase) * 0.05;
                }

                double final_angle = base_angle + spiral_offset;

                cr.save();
                cr.translate(center_x, center_y);
                cr.rotate(final_angle);

                cr.move_to(0, 0);
                cr.curve_to(
                    petal_size * 0.5, -petal_size * 0.8,
                    petal_size * 0.5, -petal_size * 0.8,
                    petal_size, -petal_size * 0.35
                );
                cr.curve_to(
                    petal_size * 0.8, petal_size * 0.3,
                    petal_size * 0.8, petal_size * 0.3,
                    0, 0
                );

                var pattern = new Cairo.Pattern.radial(0, 0, 0, 0, 0, petal_size);
                pattern.add_color_stop_rgba(0, petal_color.red, petal_color.green, petal_color.blue, petal_color.alpha);
                pattern.add_color_stop_rgba(1, petal_color.red, petal_color.green, petal_color.blue, petal_color.alpha * 0.5);

                cr.set_source(pattern);
                cr.fill();

                cr.restore();
            }

            cr.set_source_rgba(0.0f, 0.0f, 0.0f, 0.9f);
            cr.arc(center_x, center_y, petal_size * 0.1, 0, Math.PI * 2);
            cr.fill();
        }
    }
}
