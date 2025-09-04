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
            double center_x = width / 2.0; // 188.5
            double center_y = height / 2.0; // 188.5

            // Fixed dimensions: 377x377 area, 355px max diameter, 211px min diameter
            double max_radius = 177.5; // 355px diameter
            double min_radius = 105.5; // 211px diameter

            // Calculate size multiplier based on breath phase
            double size_multiplier;
            double min_multiplier = min_radius / max_radius; // ~0.594

            if (breath_phase < 0.25) {
                // Inhale: grow from min to max
                size_multiplier = min_multiplier + (breath_phase * 4.0) * (1.0 - min_multiplier);
            } else if (breath_phase < 0.5) {
                // Hold inhaled: stay at max
                size_multiplier = 1.0;
            } else if (breath_phase < 0.75) {
                // Exhale: shrink from max to min
                size_multiplier = 1.0 - ((breath_phase - 0.5) * 4.0) * (1.0 - min_multiplier);
            } else {
                // Hold exhaled: stay at min
                size_multiplier = min_multiplier;
            }

            // Create Sunny shape and clip to it
            cr.save();

            // Create concentric Sunny shapes with gradient effect
            int layers = 18;
            for (int i = 0; i < layers; i++) {
                cr.save();

                // Calculate radius factor from 1.0 down to 0.1
                double radius_factor = 1.0 - (0.9 * i / (layers - 1));
                double radius = Math.fmin(width, height) * 0.4;
                double current_radius = radius * radius_factor * size_multiplier;

                double r, g, b;

                if (i == 0) {
                    // Outermost layer: #b0b5fe
                    r = 0.69;
                    g = 0.71;
                    b = 0.996;
                } else if (i == 1) {
                    // Second outer layer: #c6c7fe
                    r = 0.776;
                    g = 0.78;
                    b = 0.996;
                } else {
                    // Yellow gradient from #e3ed86 to #eef37b to #f1fe9e
                    double t = (double)(i - 2) / (layers - 3);

                    if (t < 0.5) {
                        // Gradient from #e3ed86 to #eef37b
                        double blend = t / 0.5;
                        r = 0.89 + (0.933 - 0.89) * blend;
                        g = 0.929 + (0.953 - 0.929) * blend;
                        b = 0.525 - (0.525 - 0.482) * blend;
                    } else {
                        // Gradient from #eef37b to #f1fe9e
                        double blend = (t - 0.5) / 0.5;
                        r = 0.933 + (0.945 - 0.933) * blend;
                        g = 0.953 + (0.996 - 0.953) * blend;
                        b = 0.482 + (0.62 - 0.482) * blend;
                    }
                }

                cr.set_source_rgb(r, g, b);
                draw_sunny_shape(cr, center_x, center_y, current_radius);
                cr.fill();

                cr.restore();
            }
            cr.restore();

            // Draw center - Flower shape at constant size, solid color
            double center_size = 12.0; // Fixed size, no scaling
            draw_flower_shape(cr, center_x, center_y, center_size,
                            {0.137f, 0.224f, 0.553f, 1.0f}); // Dark blue, solid
        }

        private void draw_sunny_shape(Cairo.Context cr, double center_x, double center_y, double radius) {
            int waves = 8;
            int points_per_wave = 20;
            int total_points = waves * points_per_wave;

            cr.new_path();

            for (int i = 0; i <= total_points; i++) {
                double angle = (2 * Math.PI * i) / total_points;

                // Create smooth wave pattern for Sunny shape
                // Modulate radius with sine wave for smooth undulations
                // Use cosine to align peaks with cardinal directions
                double wave_depth = 0.12;
                double modulation = 1.0 + wave_depth * Math.cos(waves * angle);
                double r = radius * modulation;

                // Start from top (no rotation offset needed)
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
    }
}
