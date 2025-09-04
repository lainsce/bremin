namespace Bremin {
    public class BreminApp : He.Application {
        private const GLib.ActionEntry APP_ENTRIES[] = {
            { "quit", quit },
        };

        public BreminApp () {
            Object (application_id: "io.github.lainsce.Bremin");
        }

        public static int main (string[] args) {
            // Initialize GStreamer
            Gst.init (ref args);

            var app = new BreminApp ();
            return app.run (args);
        }

        public override void activate () {
            this.active_window?.present ();
        }

        public override void startup () {
            Gdk.RGBA accent_color = { };
            accent_color.parse ("#23398d");

            Gdk.RGBA secondary_color = { };
            secondary_color.parse ("#535d2e");

            Gdk.RGBA tertiary_color = { };
            tertiary_color.parse ("#004a7a");

            default_accent_color = He.from_gdk_rgba (accent_color);
            default_secondary_color = He.from_gdk_rgba (secondary_color);
            default_tertiary_color = He.from_gdk_rgba (tertiary_color);
            override_accent_color = true;

            resource_base_path = "/io/github/lainsce/Bremin";

            base.startup ();

            add_action_entries (APP_ENTRIES, this);

            new MainWindow (this);
        }
    }
}
