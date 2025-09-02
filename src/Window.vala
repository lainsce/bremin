namespace Bremin {
    public class MainWindow : He.ApplicationWindow {
        private Gtk.Stack main_stack;
        private Gtk.Stack session_stack;
        private Gtk.Box main_box;
        private SetupView setup_view;
        private SessionView session_view;
        private ReportView report_view;
        private StatsView stats_view;
        private He.AppBar header_bar;
        private He.AppBar nav_header_bar;

        public MainWindow(He.Application app) {
            Object(application: app);
            setup_ui();
        }

        private void setup_ui() {
            title = "Bremin";
            default_width = 500;
            default_height = 600;

            main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            set_child(main_box);

            main_stack = new Gtk.Stack();
            main_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);

            var nav_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            nav_box.set_size_request(106, -1);

            nav_header_bar = new He.AppBar();
            nav_header_bar.show_left_title_buttons = true;
            nav_header_bar.show_right_title_buttons = false;
            nav_box.append(nav_header_bar);

            var nav = new He.NavigationRail();
            nav.stack = main_stack;
            nav_box.append(nav);
            main_box.append(nav_box);

            var view_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            header_bar = new He.AppBar();
            header_bar.show_left_title_buttons = false;
            header_bar.show_right_title_buttons = true;
            view_box.append(header_bar);

            setup_view = new SetupView(this);
            session_view = new SessionView();
            report_view = new ReportView(this);
            stats_view = new StatsView();

            session_stack = new Gtk.Stack();
            session_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

            session_stack.add_titled(setup_view, "setup", "Setup");
            session_stack.add_titled(session_view, "session", "Session");
            session_stack.add_titled(report_view, "report", "Report");

            main_stack.add_titled(session_stack, "session", "Session");
            main_stack.get_page(session_stack).set_icon_name("user-home-symbolic");
            main_stack.add_titled(stats_view, "stats", "Progress");
            main_stack.get_page(stats_view).set_icon_name("checkbox-checked-symbolic");
            view_box.append(main_stack);

            main_box.append(view_box);

            var key_controller = new Gtk.EventControllerKey();
            key_controller.key_pressed.connect(on_key_pressed);
            main_box.add_controller(key_controller);
        }

        private bool on_key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
            if (keyval == Gdk.Key.Escape) {
                if (session_stack.get_visible_child() == session_view) {
                    session_view.stop_session();
                    session_stack.set_visible_child(setup_view);
                    return true;
                } else if (session_stack.get_visible_child() == report_view) {
                    session_stack.set_visible_child(setup_view);
                    return true;
                }
            }
            return false;
        }

        public void start_breathing_session(int duration_minutes, bool sounds_enabled, bool jitter_enabled) {
            session_view.start_session(duration_minutes, sounds_enabled, jitter_enabled);
            session_stack.set_visible_child(session_view);
        }

        public void session_completed(int duration_minutes, int breath_count) {
            report_view.show_report(duration_minutes, breath_count);
            session_stack.set_visible_child(report_view);
        }

        public void report_finished(int duration_minutes, int breath_count) {
            stats_view.add_session_data(duration_minutes, breath_count);
            main_stack.set_visible_child(stats_view);
        }

        public void return_to_setup() {
            session_stack.set_visible_child(setup_view);
        }
    }
}
