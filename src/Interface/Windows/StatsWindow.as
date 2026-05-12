class StatsWindow : Window {
    bool m_loadingStats;
    bool m_loadingError;
    RunStatistics@ m_runStats;
    bool m_focusTab;

    string get_Title() override {
        return Icons::BarChart + " Run Statistics";
    }

    void LoadStats(ref@ runData) {
        m_loadingStats = true;
        StatsView::ResetFilters();

        try {
            auto data = cast<Json::Value>(runData);

            if (data is null) {
                Log::Error("Failed to load run stats");
                m_loadingError = true;
                m_loadingStats = false;
                return;
            }

            @m_runStats = RunStatistics(data);
            m_focusTab = true;
        } catch {
            Log::Error("Failed to calculate the run statistics: " + getExceptionInfo(), true);
            m_loadingError = true;
        }

        m_loadingStats = false;
    }

    void RenderWindow() override {
        if (m_loadingStats) {
            UI::CenteredText(Icons::AnimatedHourglass + " Loading run data");
            return;
        }

        if (m_loadingError) {
            UI::CenteredText("\\$f00" + Icons::Times + "\\$z An error occurred while calculating the statistics");
            return;
        }

        if (m_runStats is null || m_runStats.Maps.IsEmpty()) {
            UI::CenteredText("No statistics found");
            return;
        }

        UI::BeginTabBar("Tabs", UI::TabBarFlags::FittingPolicyScroll);

        UI::TabItemFlags tabFlags = UI::TabItemFlags::None;

        if (m_focusTab) {
            tabFlags = UI::TabItemFlags::SetSelected;
            m_focusTab = false;
        }

        if (UI::BeginTabItem("General", tabFlags)) {
            StatsView::GeneralTab(m_runStats);
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Attempts")) {
            StatsView::AttemptsTab(m_runStats);
            UI::EndTabItem();
        }

        bool hasPace = m_runStats.Mode == RMC::GameMode::Challenge || m_runStats.Mode == RMC::GameMode::Together;

        UI::BeginDisabled(!hasPace);

        if (UI::BeginTabItem("Pace")) {
            StatsView::PaceTab(m_runStats);
            UI::EndTabItem();
        }

        UI::EndDisabled();

        if (!hasPace) {
#if TMNEXT
            UI::SetItemTooltip("Pace statistics are only available for Challenge / Together runs");
#else
            UI::SetItemTooltip("Pace statistics are only available for Challenge runs");
#endif
        }

        if (UI::BeginTabItem("Progress")) {
            StatsView::ProgressTab(m_runStats);
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Maps")) {
            StatsView::MapTab(m_runStats);
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Other")) {
            StatsView::OtherTab(m_runStats);
            UI::EndTabItem();
        }

#if TMNEXT
        if (m_runStats.Mode == RMC::GameMode::Together && UI::BeginTabItem("Players")) {
            StatsView::PlayersTab(m_runStats);
            UI::EndTabItem();
        }
#endif

        UI::EndTabBar();
    }
}
