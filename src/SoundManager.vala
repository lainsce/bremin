namespace Bremin {
    public class SoundManager : GLib.Object {
        private Gst.Element pipeline;
        private bool is_initialized = false;

        public SoundManager() {
            initialize_gstreamer();
        }

        private void initialize_gstreamer() {
            // Create a simple playbin pipeline for playing sounds
            pipeline = Gst.ElementFactory.make("playbin", "audio-player");
            if (pipeline == null) {
                warning("Failed to create GStreamer playbin element");
                return;
            }

            is_initialized = true;
        }

        public void play_phase_ding() {
            if (!is_initialized || pipeline == null) {
                return;
            }

            try {
                // Stop any currently playing sound
                pipeline.set_state(Gst.State.NULL);

                // Generate a soft, pleasant ding sound programmatically
                // Using audiotestsrc with sine wave for a soft ding
                var audio_pipeline = """
                    audiotestsrc wave=sine freq=400 volume=0.1 num-buffers=10 !
                    audioconvert !
                    audioresample !
                    autoaudiosink
                """;

                var temp_pipeline = Gst.parse_launch(audio_pipeline);
                if (temp_pipeline != null) {
                    temp_pipeline.set_state(Gst.State.PLAYING);

                    // Set up a bus to listen for end-of-stream
                    var bus = temp_pipeline.get_bus();
                    bus.add_signal_watch();
                    bus.message.connect((msg) => {
                        switch (msg.type) {
                            case Gst.MessageType.EOS:
                                temp_pipeline.set_state(Gst.State.NULL);
                                bus.remove_signal_watch();
                                break;
                            case Gst.MessageType.ERROR:
                                temp_pipeline.set_state(Gst.State.NULL);
                                bus.remove_signal_watch();
                                break;
                            default:
                                break;
                        }
                    });
                }
            } catch (Error e) {
                // Silently handle error - sound is optional
                debug("Sound playback error: %s", e.message);
            }
        }

        public void play_completion_sound() {
            if (!is_initialized || pipeline == null) {
                return;
            }

            try {
                // Stop any currently playing sound
                pipeline.set_state(Gst.State.NULL);

                // Generate a more elaborate completion sound with multiple tones
                var audio_pipeline = """
                    audiotestsrc wave=sine freq=523 volume=0.4 num-buffers=8 !
                    audioconvert ! audioresample ! queue ! audiomixer name=mix !
                    autoaudiosink
                    audiotestsrc wave=sine freq=659 volume=0.3 num-buffers=8 !
                    audioconvert ! audioresample ! queue ! mix.
                    audiotestsrc wave=sine freq=784 volume=0.2 num-buffers=8 !
                    audioconvert ! audioresample ! queue ! mix.
                """;

                var temp_pipeline = Gst.parse_launch(audio_pipeline);
                if (temp_pipeline != null) {
                    temp_pipeline.set_state(Gst.State.PLAYING);

                    var bus = temp_pipeline.get_bus();
                    bus.add_signal_watch();
                    bus.message.connect((msg) => {
                        switch (msg.type) {
                            case Gst.MessageType.EOS:
                                temp_pipeline.set_state(Gst.State.NULL);
                                bus.remove_signal_watch();
                                break;
                            case Gst.MessageType.ERROR:
                                temp_pipeline.set_state(Gst.State.NULL);
                                bus.remove_signal_watch();
                                break;
                            default:
                                break;
                        }
                    });
                }
            } catch (Error e) {
                debug("Completion sound playback error: %s", e.message);
            }
        }
    }
}
