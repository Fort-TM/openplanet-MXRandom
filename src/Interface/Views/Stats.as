namespace StatsView {
    AttemptsPlot g_attemptsPlot = AttemptsPlot::Histogram;
    ProgressPlot g_progressPlot = ProgressPlot::Medals_Timeline;
    RMC::MapResult g_selectedResult = RMC::MapResult::None;
    string g_search = "";
    bool g_highlighted = false;

    enum AttemptsPlot {
        Histogram,
        Scatter
    };

    enum ProgressPlot {
        Medals_Timeline,
        Timer_Progress,
        Time_Gain_and_Loss
    };

    void ResetFilters() {
        g_attemptsPlot = AttemptsPlot::Histogram;
        g_progressPlot = ProgressPlot::Medals_Timeline;
        g_selectedResult = RMC::MapResult::None;
        g_search = "";
        g_highlighted = false;
    }

    void GeneralTab(RunStatistics@ stats) {
        UI::BeginChild("GeneralChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        for (uint i = 0; i < stats.GeneralStats.Length; i++) {
            array<string> stat = stats.GeneralStats[i];
            bool centered = i % 2 == 1;

            if (!centered) {
                UI::RenderStat(stat[0], stat[1], stat[2]);
            } else {
                UI::RenderCenteredStat(stat[0], stat[1], stat[2]);

                if (i != stats.GeneralStats.Length - 1) {
                    UI::NewLine();
                    UI::Separator();
                    UI::NewLine();
                }
            }
        }

        UI::EndChild();
    }

    void AttemptsTab(RunStatistics@ stats) {
        UI::BeginChild("AttemptsChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::RenderStat("Total Attempts", tostring(stats.TotalAttempts));

        UI::RenderCenteredStat("Average Attempts", Text::Format("%.2f", stats.AverageAttempts));

        UI::PaddedHeaderSeparator("Attempts Graph");

        UI::SetNextItemWidth(150);

        if (UI::BeginCombo("##AttemptsPlot", tostring(g_attemptsPlot))) {
            for (int i = 0; i <= AttemptsPlot::Scatter; i++) {
                if (UI::Selectable(tostring(AttemptsPlot(i)), g_attemptsPlot == AttemptsPlot(i))) {
                    g_attemptsPlot = AttemptsPlot(i);
                }
            }

            UI::EndCombo();
        }

        switch (g_attemptsPlot) {
            case AttemptsPlot::Histogram:
                Plots::AttemptsHistogramPlot(stats);

                break;
            case AttemptsPlot::Scatter:
                UI::SameLine();
                UI::Separator(UI::SeparatorFlags::Vertical);
                UI::SameLine();

                Plots::RenderSettings(false);
                Plots::AttemptsScatterPlot(stats);

                break;
            default:
                break;
        }

        UI::EndChild();
    }

    void PaceTab(RunStatistics@ stats) {
        UI::BeginChild("PaceChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::RenderStat("Lowest Pace", Text::Format("%.2f", stats.LowestPace));

        UI::RenderCenteredStat("Highest Pace", Text::Format("%.2f", stats.HighestPace));

        UI::PaddedHeaderSeparator("Pace Graph");

        Plots::RenderSettings();

        Plots::PacePlot(stats);

        UI::EndChild();
    }

    void ProgressTab(RunStatistics@ stats) {
        UI::BeginChild("ProgressChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::PaddedHeaderSeparator("Progress Graph");

        if (stats.Mode == RMC::GameMode::Survival) {
            UI::SetNextItemWidth(175);

            if (UI::BeginCombo("##ProgressPlot", tostring(g_progressPlot).Replace("_", " "))) {
                for (int i = 0; i <= ProgressPlot::Time_Gain_and_Loss; i++) {
                    if (UI::Selectable(tostring(ProgressPlot(i)).Replace("_", " "), g_progressPlot == ProgressPlot(i))) {
                        g_progressPlot = ProgressPlot(i);
                    }
                }

                UI::EndCombo();
            }

            UI::SameLine();
            UI::Separator(UI::SeparatorFlags::Vertical);
            UI::SameLine();
        }

        Plots::RenderSettings();

        switch (g_progressPlot) {
            case ProgressPlot::Timer_Progress:
                Plots::TimerProgressPlot(stats);

                break;
            case ProgressPlot::Medals_Timeline:
                Plots::MedalsTimeline(stats);

                break;
            case ProgressPlot::Time_Gain_and_Loss:
                Plots::TimeGainLossPlot(stats);

                break;
        }

        UI::EndChild();
    }

    void MapTab(RunStatistics@ stats) {
        UI::BeginChild("MapsChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        string resultName = tostring(g_selectedResult).Replace("_", " ");

        if (g_selectedResult == RMC::MapResult::None) {
            resultName = "All";
        }

        UI::SetNextItemWidth(150);

        if (UI::BeginCombo("Result##Combo", resultName)) {
            for (int i = 0; i < RMC::MapResult::Broken_Skip; i++) {
                int count = stats.ResultCounts[i];
                string comboName = tostring(RMC::MapResult(i)).Replace("_", " ") + " (" + count + ")";

                if (i == RMC::MapResult::None) {
                    comboName = "All (" + stats.Maps.Length + ")";
                }

                UI::BeginDisabled(i > 0 && count == 0);

                if (UI::Selectable(comboName, g_selectedResult == RMC::MapResult(i))) {
                    g_selectedResult = RMC::MapResult(i);
                    stats.Filter(RMC::MapResult(i), g_search, g_highlighted);
                }

                UI::EndDisabled();
            }

            UI::EndCombo();
        }

        UI::SameLine();
        UI::Separator(UI::SeparatorFlags::Vertical);
        UI::SameLine();

        bool oldValue = g_highlighted;

        g_highlighted = UI::Checkbox("Highlighted", g_highlighted);
        UI::SetItemTooltip("Only display highlighted maps during the run.\n\nTo highlight a map, use the \"Highlight current map\" hotkey.");

        if (oldValue != g_highlighted) {
            stats.Filter(g_selectedResult, g_search, g_highlighted);
        }

        UI::SameLine();
        UI::Separator(UI::SeparatorFlags::Vertical);
        UI::SameLine();

        bool changed = false;

        g_search = UI::InputText("Search", g_search, changed);
        UI::SetItemTooltip("Search by map name or author");

        if (changed) {
            stats.Filter(g_selectedResult, g_search, g_highlighted);
        }

        Render::StatsMapsList(stats);

        UI::EndChild();
    }

    void OtherTab(RunStatistics@ stats) {
        vec2 region = UI::GetWindowSize();

        UI::BeginChild("MapTagsChild", vec2(region.x * .45, -1), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::RenderStat("Total Map Tags", tostring(stats.MapTagsCounter.Length));

        UI::NewLine();
        UI::Separator();
        UI::NewLine();

        Render::MapTagsList(stats);

        UI::EndChild();

        UI::SameLine();

        UI::BeginChild("MapAuthorsChild", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::RenderStat("Total Map Authors", tostring(stats.MapAuthorsCounter.Length));

        UI::NewLine();
        UI::Separator();
        UI::NewLine();

        Render::MapAuthorsList(stats);

        UI::EndChild();

    }

    void PlayersTab(RunStatistics@ stats) {
        vec2 region = UI::GetWindowSize();

        UI::BeginChild("PlayersChildLeft", vec2(region.x * .66, -1), UI::ChildFlags::AlwaysUseWindowPadding);

        Render::PlayersList(stats);

        UI::EndChild();

        UI::SameLine();

        UI::BeginChild("PlayersChildRight", vec2(), UI::ChildFlags::AlwaysUseWindowPadding);

        UI::RenderStat("Total Players", tostring(stats.PlayerCounter.Length), "who got at least 1 medal");

        if (stats.PlayerCounter.Length > 0) {
            UI::NewLine();
            UI::Separator();
            UI::NewLine();

            CounterValue@ player = stats.PlayerCounter[0];

            string medalString = tostring(player.Count) + " " + Pluralize(tostring(stats.Settings.GoalMedal), player.Count);

            if (stats.Settings.GoalMedal != Medals::Bronze) {
                Medals secondMedal = Medals(stats.Settings.GoalMedal - 1);
                medalString += ", " + player.SecondaryCount + " " + Pluralize(tostring(secondMedal), player.SecondaryCount);
            }

            UI::RenderStat("Best Player", player.Name, medalString);
        }

        UI::EndChild();
    }
}
