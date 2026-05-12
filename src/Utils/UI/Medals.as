namespace UI {
    // From Better TOTD by Xertrov https://github.com/XertroV/tm-better-totd
    const string BRONZE_ICON   = "\\$964" + Icons::Circle + " \\$z";
    const string SILVER_ICON   = "\\$899" + Icons::Circle + " \\$z";
    const string GOLD_ICON     = "\\$db4" + Icons::Circle + " \\$z";
    const string AT_ICON       = "\\$071" + Icons::Circle + " \\$z";
    const string WR_ICON       = "\\$C91" + Icons::Trophy + " \\$z";

    const string RED_COLOR     = "\\$F77";
    const string BLUE_COLOR    = "\\$77F";
    const string GREY_COLOR    = "\\$888";

    const vec4 BRONZE_COLOR = vec4(153. / 255, 102. / 255, 68. / 255, 1);
    const vec4 SILVER_COLOR = vec4(136. / 255, 153. / 255, 153. / 255, 1);
    const vec4 GOLD_COLOR   = vec4(221. / 255, 187. / 255, 68. / 255, 1);
    const vec4 AT_COLOR     = vec4(0. / 255, 119. / 255, 17. / 255, 1);
    const vec4 WR_COLOR     = vec4(204. / 255, 153. / 255, 17. / 255, 1);

    vec4 GetMedalColor(Medals medal) {
        switch (medal) {
#if TMNEXT
            case Medals::WR:
                return WR_COLOR;
#endif
            case Medals::Author:
                return AT_COLOR;
            case Medals::Gold:
                return GOLD_COLOR;
            case Medals::Silver:
                return SILVER_COLOR;
            case Medals::Bronze:
                return BRONZE_COLOR;
            default:
                return vec4(1);
        }
    }

    string GetMedalIcon(Medals medal) {
        switch (medal) {
#if TMNEXT
            case Medals::WR:
                return WR_ICON;
#endif
            case Medals::Author:
                return AT_ICON;
            case Medals::Gold:
                return GOLD_ICON;
            case Medals::Silver:
                return SILVER_ICON;
            case Medals::Bronze:
                return BRONZE_ICON;
            default:
                return "";
        }
    }

    string FormatTime(int time, MapTypes mapType) {
        switch (mapType) {
            case MapTypes::Stunt:
                if (time < 1) return "-";

                return tostring(time) + " pts";
            case MapTypes::Platform:
                if (time < 0) return "-";

                return tostring(time) + " respawns";
            case MapTypes::Race:
            default:
                if (time < 1) {
                    return "-:--.---";
                }

                return Time::Format(time);
        }
    }

    string FormatDelta(int medalTime, int pbTime, MapTypes mode) {
        if (medalTime < 0 || pbTime < 0 || uint(pbTime) == uint(-1)) return "";

        int delta = medalTime - pbTime;

        switch (mode) {
            case MapTypes::Stunt:
                if (delta > 0) {
                    return RED_COLOR + "\u2212" + delta;
                } else if (delta < 0) {
                    return BLUE_COLOR + "+" + Math::Abs(delta);
                } else {
                    return GREY_COLOR + "\u2212";
                }
            case MapTypes::Platform:
                if (delta > 0) {
                    return BLUE_COLOR + "\u2212" + delta;
                } else if (delta < 0) {
                    return RED_COLOR + "+" + Math::Abs(delta);
                } else {
                    return GREY_COLOR + "\u2212";
                }
            case MapTypes::Race:
            default:
                if (delta > 0) {
                    return BLUE_COLOR + "\u2212" + Time::Format(delta);
                } else if (delta < 0) {
                    return RED_COLOR + "+" + Time::Format(Math::Abs(delta));
                } else {
                    return GREY_COLOR + "+" + Time::Format(delta);
                }
        }
    }
}
