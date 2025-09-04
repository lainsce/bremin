namespace Bremin {
    public string get_daily_sentence() {
        string[] daily_phrases = {
            "Take a moment for yourself today, %s. Your breathing practice is a gift.",
            "Every breath is a step towards tranquility, %s. Embrace this calm.",
            "You deserve this peaceful time, %s. Let your breath guide you.",
            "%s, in stillness you find strength. Breathe deeply and feel centered.",
            "Your mindfulness inspires growth, %s. Each session builds resilience.",
            "Today is a new opportunity for peace, %s. Let breath be your anchor.",
            "Breathe with intention today, %s. Every moment contributes to happiness.",
            "%s, your journey to wellness begins with a breath. Honor your practice.",
            "In this moment of breathing, %s, you are where you need to be.",
            "Your dedication to self-care shines bright, %s. Embrace the calm.",
            "Let today's practice remind you, %s, that peace exists in every breath.",
            "%s, you have the power to create calm in any moment. Trust your breath.",
            "Each breathing session is a gift to your future self, %s. Invest in peace.",
            "Your breath is your constant companion, %s. Let it guide you.",
            "Take pride in this mindful choice, %s. You nurture your inner garden.",
            "%s, in the rhythm of your breath, discover the rhythm of peace.",
            "Your breathing practice is self-love, %s. Cherish this time.",
            "Today's breath work builds tomorrow's calm, %s. Keep nurturing peace.",
            "%s, let your breath wash away tensions and restore your balance.",
            "Every mindful breath is a victory, %s. Celebrate your commitment.",
            "Your journey to inner peace unfolds with each breath, %s. Trust it.",
            "%s, in stillness you find clarity. Let your breath illuminate your path.",
            "Breathing mindfully is a superpower, %s. Use it to transform your day.",
            "Your presence in this moment is powerful, %s. Breathe and embrace strength.",
            "%s, let your breath be the bridge between stress and serenity.",
            "Each session builds your foundation of peace, %s. You grow stronger.",
            "Your breath holds infinite wisdom, %s. Listen to what it teaches today.",
            "%s, in choosing to breathe mindfully, you choose to flourish.",
            "Let your breath remind you, %s, that you have everything you need within.",
            "Your commitment to mindfulness is beautiful, %s. Let it bloom.",
            "Today's breathing is tomorrow's peace, %s. Plant seeds of tranquility.",
            "%s, your breath is a gentle teacher. Be open to its lessons.",
            "In the space between breaths, %s, infinite possibilities for peace exist.",
            "Your mindful breathing creates ripples of calm, %s. Feel them spread.",
            "%s, trust in the healing power of your breath. It knows what you need.",
            "Each breath is a new beginning, %s. What will you create with this moment?",
            "Your practice is a lighthouse in life's storms, %s. Let it guide you.",
            "%s, breathe with gratitude today. Your body and mind will thank you.",
            "In mindful breathing, you find your true home, %s. Welcome back.",
            "Your breath is poetry in motion, %s. Write beautiful verses of peace.",
            "%s, let your breathing practice be a love letter to your soul.",
            "Every breath connects you to the present moment, %s. Magic happens here.",
            "Your dedication to breathing mindfully is changing you, %s. Embrace it.",
            "%s, in the symphony of your breath, hear the music of inner harmony.",
            "Your breathing practice is a daily miracle, %s. Witness its power unfold.",
            "Let your breath be your compass today, %s. It always points toward peace.",
            "%s, you are exactly the person who deserves this moment of calm.",
            "Your mindful breath is a bridge to your best self, %s. Cross it.",
            "In breathing consciously, you choose consciousness, %s. Beautiful choice.",
            "%s, may your breath today plant seeds of joy that bloom all week."
        };

        var now = new GLib.DateTime.now_local();
        int day_of_year = now.get_day_of_year();
        int phrase_index = (day_of_year - 1) % daily_phrases.length;

        string user_name = GLib.Environment.get_real_name();
        if (user_name == null || user_name == "" || user_name == "Unknown") {
            user_name = GLib.Environment.get_user_name();
        }
        if (user_name == null || user_name == "") {
            user_name = "Friend";
        }

        return daily_phrases[phrase_index].printf(user_name);
    }

    public static double ease_in_out_cubic(double t) {
        return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
    }

    public static double ease_in_out_sine(double t) {
        return -(Math.cos(Math.PI * t) - 1) / 2;
    }

    public static double clamp(double value, double min, double max) {
        return Math.fmax(min, Math.fmin(max, value));
    }

    public static Gdk.RGBA rgba_from_string(string color_string) {
        Gdk.RGBA color = {};
        if (color.parse(color_string)) {
            return color;
        }
        // Return black as fallback
        return {0.0f, 0.0f, 0.0f, 1.0f};
    }

    public static string format_duration(int total_seconds) {
        int minutes = total_seconds / 60;
        int seconds = total_seconds % 60;
        return "%02d:%02d".printf(minutes, seconds);
    }
}
