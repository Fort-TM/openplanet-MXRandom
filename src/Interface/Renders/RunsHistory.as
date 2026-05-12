namespace Render {
    void RunsHistory() {
        UI::ListClipper clipper(RunHistoryJson.Length);

        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                Json::Value@ run = RunHistoryJson[i];

                UI::PushID("Run" + i);

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text(tostring(RMC::GameMode(int(run["GameMode"]))));

                UI::TableNextColumn();
                UI::Text(tostring(RMC::Category(int(run["Settings"]["Category"]))));

                UI::TableNextColumn();
                UI::Text(tostring(Medals(int(run["Settings"]["GoalMedal"]))));

                UI::TableNextColumn();
                UI::Text(Time::FormatString("%d %b %Y at %R", run["PlayedAt"]));

                UI::TableNextColumn();
                UI::Text(Time::Format(run["TotalTime"]));

                UI::TableNextColumn();
                UI::Text(tostring(int(run["PrimaryCounterValue"])));

                UI::TableNextColumn();
                UI::Text(tostring(int(run["SecondaryCounterValue"])));

                UI::TableNextColumn();

                if (UI::Button(Icons::BarChart + " Stats")) {
                    if (!UI::IsOverlayShown()) {
                        UI::ShowOverlay();
                    }

                    startnew(CoroutineFuncUserdata(statsMenu.LoadStats), run);
                    statsMenu.Open();
                }

                UI::PopID();
            }
        }
    }
}
