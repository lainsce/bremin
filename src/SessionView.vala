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
        private SoundManager sound_manager;
        private string current_instruction = "";

        public SessionView() {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 6);
            sound_manager = new SoundManager();
            setup_ui();
        }

        private void setup_ui() {
            margin_end = 18;
            margin_start = 18;
            margin_bottom = 12;

            time_label = new Gtk.Label("");
            time_label.add_css_class("big-display");
            time_label.margin_top = 50;
            append(time_label);

            breathing_area = new Gtk.DrawingArea();
            breathing_area.set_size_request(377, 377);
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
            current_instruction = "";

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
                double phase_progress = breath_phase * 4.0;
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

            // Play sound on phase transitions
            if (sounds_enabled && instruction != current_instruction) {
                sound_manager.play_phase_ding();
                current_instruction = instruction;
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

            // Play completion sound if sounds are enabled
            if (sounds_enabled) {
                sound_manager.play_completion_sound();
            }

            var window = get_root() as MainWindow;
            window?.session_completed(total_seconds / 60, breath_count);
        }

        private void draw_breathing_flower(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            double center_x = width / 2.0;
            double center_y = height / 2.0;

            double max_radius = 177.5;
            double min_radius = 105.5;
            double min_multiplier = min_radius / max_radius;

            // Calculate base size multiplier
            double base_size_multiplier;
            if (breath_phase < 0.25) {
                base_size_multiplier = min_multiplier + (breath_phase * 4.0) * (1.0 - min_multiplier);
            } else if (breath_phase < 0.5) {
                base_size_multiplier = 1.0;
            } else if (breath_phase < 0.75) {
                base_size_multiplier = 1.0 - ((breath_phase - 0.5) * 4.0) * (1.0 - min_multiplier);
            } else {
                base_size_multiplier = min_multiplier;
            }

            cr.save();

            int layers = 18;
            double time_offset = GLib.get_monotonic_time() / 1000000.0;

            for (int i = 0; i < layers; i++) {
                cr.save();

                double radius_factor = 1.0 - (0.9 * i / (layers - 1));
                double radius = Math.fmin(width, height) * 0.4;

                // Staggered animation - each layer lags behind
                double layer_lag = i * 0.015;
                double staggered_phase = breath_phase - layer_lag;
                if (staggered_phase < 0.0) staggered_phase += 1.0;

                // Calculate staggered size multiplier
                double staggered_size_multiplier;
                if (staggered_phase < 0.25) {
                    staggered_size_multiplier = min_multiplier + (staggered_phase * 4.0) * (1.0 - min_multiplier);
                } else if (staggered_phase < 0.5) {
                    staggered_size_multiplier = 1.0;
                } else if (staggered_phase < 0.75) {
                    staggered_size_multiplier = 1.0 - ((staggered_phase - 0.5) * 4.0) * (1.0 - min_multiplier);
                } else {
                    staggered_size_multiplier = min_multiplier;
                }

                double current_radius = radius * radius_factor * staggered_size_multiplier;

                // Jitter rotation for blooming/wilting effect
                double rotation = 0.0;
                if (jitter_enabled) {
                    double jitter_speed = 0.5 + (i * 0.1);
                    double bloom_factor = Math.sin(time_offset * jitter_speed + i * 0.3) * 0.08;
                    rotation = bloom_factor * (1.0 + i * 0.1);
                }

                cr.translate(center_x, center_y);
                cr.rotate(rotation);
                cr.translate(-center_x, -center_y);

                double r, g, b, a = 1.0;

                if (i == 0) {
                    r = 0.69; g = 0.71; b = 0.996;
                } else if (i == 1) {
                    r = 0.776; g = 0.78; b = 0.996;
                } else {
                    // Yellow layers - smoother alpha transitions throughout cycle
                    double t = (double)(i - 2) / (layers - 3);

                    if (t < 0.5) {
                        double blend = t / 0.5;
                        r = 0.89 + (0.933 - 0.89) * blend;
                        g = 0.929 + (0.953 - 0.929) * blend;
                        b = 0.525 - (0.525 - 0.482) * blend;
                    } else {
                        double blend = (t - 0.5) / 0.5;
                        r = 0.933 + (0.945 - 0.933) * blend;
                        g = 0.953 + (0.996 - 0.953) * blend;
                        b = 0.482 + (0.62 - 0.482) * blend;
                    }

                    // Smooth alpha based on breathing cycle - avoid sudden transitions
                    double alpha_base = 1.0;
                    double fade_strength = 0.4; // Reduced from 0.7 for subtler effect

                    if (staggered_phase >= 0.2 && staggered_phase <= 0.55) {
                        // Hold inhaled - smooth fade using sine curve
                        double hold_progress = (staggered_phase - 0.2) / 0.35;
                        double fade_factor = Math.sin(hold_progress * Math.PI);
                        alpha_base = 1.0 - (fade_factor * fade_strength);
                    } else if (staggered_phase >= 0.7) {
                        // Hold exhaled - smooth fade using sine curve
                        double hold_progress = (staggered_phase - 0.7) / 0.3;
                        if (hold_progress > 1.0) hold_progress = 1.0;
                        double fade_factor = Math.sin(hold_progress * Math.PI);
                        alpha_base = 1.0 - (fade_factor * fade_strength);
                    }

                    a = Math.fmax(0.2, alpha_base);
                }

                cr.set_source_rgba(r, g, b, a);
                draw_sunny_shape(cr, center_x, center_y, current_radius);
                cr.fill();

                cr.restore();
            }
            cr.restore();

            // Center flower at constant size
            double center_size = 12.0;
            Gdk.RGBA center_color = {0.137f, 0.224f, 0.553f, 1.0f};
            draw_flower_shape(cr, center_x, center_y, center_size, center_color);
        }

        private void draw_sunny_shape(Cairo.Context cr, double center_x, double center_y, double radius) {
            int waves = 8;
            int points_per_wave = 20;
            int total_points = waves * points_per_wave;

            cr.new_path();

            for (int i = 0; i <= total_points; i++) {
                double angle = (2 * Math.PI * i) / total_points;

                double wave_depth = 0.12;
                double modulation = 1.0 + wave_depth * Math.cos(waves * angle);
                double r = radius * modulation;

                double x = center_x + r * Math.cos(angle - Math.PI / 2);
                double y = center_y + r * Math.sin(angle - Math.PI / 2);

                if (i == 0) {
                    cr.move_to(x, y);
                } else {
                    cr.line_to(x, y);
                }
            }

            cr.close_path();
        }

        private void draw_flower_shape(Cairo.Context cr, double center_x, double center_y,
                                             double radius, Gdk.RGBA color) {
            cr.save();
            cr.translate(center_x, center_y);

            cr.new_path();

            int petals = 8;
            for (int i = 0; i < petals; i++) {
                double angle = (2.0 * Math.PI * i) / petals;

                double petal_length = radius;
                double petal_width = radius * 2;

                double tip_x = Math.cos(angle) * petal_length;
                double tip_y = Math.sin(angle) * petal_length;

                double base_width_angle1 = angle - Math.PI / 2.0;
                double base_width_angle2 = angle + Math.PI / 2.0;

                double base_x1 = Math.cos(base_width_angle1) * petal_width * 0.5;
                double base_y1 = Math.sin(base_width_angle1) * petal_width * 0.5;
                double base_x2 = Math.cos(base_width_angle2) * petal_width * 0.5;
                double base_y2 = Math.sin(base_width_angle2) * petal_width * 0.5;

                if (i == 0) {
                    cr.move_to(0, 0);
                } else {
                    cr.line_to(0, 0);
                }

                cr.curve_to(
                    base_x1 * 0.3, base_y1 * 0.3,
                    tip_x * 0.7 + base_x1 * 0.3, tip_y * 0.7 + base_y1 * 0.3,
                    tip_x, tip_y
                );

                cr.curve_to(
                    tip_x * 0.7 + base_x2 * 0.3, tip_y * 0.7 + base_y2 * 0.3,
                    base_x2 * 0.3, base_y2 * 0.3,
                    0, 0
                );
            }
            cr.close_path();

            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.fill();

            cr.restore();
        }
    }
}
