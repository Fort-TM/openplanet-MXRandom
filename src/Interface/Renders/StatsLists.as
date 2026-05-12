namespace Render {
    void StatsMapsList(RunStatistics@ stats) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));
        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(6, 2));

        if (UI::BeginTable("MapsTable", 10, UI::TableFlags::SizingFixedFit | UI::TableFlags::Hideable | UI::TableFlags::ScrollY | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg | UI::TableFlags::PadOuterX)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Time spent");
            UI::TableSetupColumn("Attempts");
            UI::TableSetupColumn("Goal time");
            UI::TableSetupColumn("Session PB");
            UI::TableSetupColumn("Delta");
            UI::TableSetupColumn("Result");
            UI::TableSetupColumn("Player");
            UI::TableSetupColumn("");
            UI::TableHeadersRow();

            UI::TableSetColumnEnabled(8, stats.Mode == RMC::GameMode::Together);

            UI::ListClipper clipper(stats.FilteredMaps.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < Math::Min(clipper.DisplayEnd, stats.FilteredMaps.Length); i++) {
                    UI::PushID("Map" + i);

                    MX::MapInfo@ map = stats.FilteredMaps[i];

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();

                    UI::Text(map.Name);
                    UI::MXMapThumbnailTooltip(map.MapId);

                    UI::TableNextColumn();
                    UI::Text(map.Username);

                    UI::TableNextColumn();
                    UI::Text(Time::Format(map.TimeSpent));

                    UI::TableNextColumn();
                    UI::Text(tostring(map.Attempts));

                    UI::TableNextColumn();
                    UI::Text(UI::FormatTime(map.GoalTime, map.Type));

                    UI::TableNextColumn();
                    UI::Text(UI::FormatTime(map.SessionPB, map.Type));

                    UI::TableNextColumn();
                    UI::Text(UI::FormatDelta(map.GoalTime, map.SessionPB, map.Type));

                    UI::TableNextColumn();
                    UI::Text(tostring(map.Result).Replace("_", " "));

                    UI::TableNextColumn();
                    UI::Text(map.PlayerName);

                    UI::TableNextColumn();

                    if (UI::ButtonColored(Icons::ExternalLink, 0.55, 1, 0.5)) {
#if DEPENDENCY_MANIAEXCHANGE
                        ManiaExchange::ShowMapInfo(map.MapId);
#else
                        OpenBrowserURL(MX_URL + "/mapshow/" + map.MapId);
#endif
                    }

                    UI::SetItemTooltip("Open on " + MX_NAME);

                    UI::SameLine();

#if TMNEXT
                    UI::BeginDisabled(!Permissions::PlayLocalMap());
#endif

                    if (UI::GreenButton(Icons::Play)) {
                        startnew(TM::LoadMap, map);
                    }

#if TMNEXT
                    UI::EndDisabled();
#endif

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }

    void MapAuthorsList(RunStatistics@ stats) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));
        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(6, 2));

        if (UI::BeginTable("AuthorsTable", 4, UI::TableFlags::SizingFixedFit | UI::TableFlags::ScrollY | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg | UI::TableFlags::PadOuterX)) {
            UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Time");
            UI::TableSetupColumn("Avg. Time");
            UI::TableSetupColumn("Maps");
            UI::TableHeadersRow();

            UI::ListClipper clipper(stats.MapAuthorsCounter.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("Author" + i);

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();

                    UI::Text(stats.MapAuthorsCounter[i].Name);

                    UI::TableNextColumn();

                    int64 authorTime = 0;

                    if (stats.TotalTimePerAuthor.Get(stats.MapAuthorsCounter[i].Name, authorTime)) {
                        UI::Text(Time::Format(authorTime));
                    }

                    UI::TableNextColumn();

                    if (authorTime > 0) {
                        int avgTime = authorTime / stats.MapAuthorsCounter[i].Count;
                        UI::Text(Time::Format(avgTime));
                    }

                    UI::TableNextColumn();
                    UI::Text(tostring(stats.MapAuthorsCounter[i].Count));

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }

    void MapTagsList(RunStatistics@ stats) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));
        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(6, 2));

        if (UI::BeginTable("TagsTable", 4, UI::TableFlags::SizingFixedFit | UI::TableFlags::ScrollY | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg | UI::TableFlags::PadOuterX)) {
            UI::TableSetupColumn("Tag", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Time");
            UI::TableSetupColumn("Avg. Time");
            UI::TableSetupColumn("Maps");
            UI::TableHeadersRow();

            UI::ListClipper clipper(stats.MapTagsCounter.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("Tag" + i);

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();

                    UI::Text(stats.MapTagsCounter[i].Name);

                    UI::TableNextColumn();

                    int64 tagTime = 0;

                    if (stats.TotalTimePerTag.Get(stats.MapTagsCounter[i].Name, tagTime)) {
                        UI::Text(Time::Format(tagTime));
                    }

                    UI::TableNextColumn();

                    if (tagTime > 0) {
                        int avgTime = tagTime / stats.MapTagsCounter[i].Count;
                        UI::Text(Time::Format(avgTime));
                    }

                    UI::TableNextColumn();
                    UI::Text(tostring(stats.MapTagsCounter[i].Count));

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }

    void PlayersList(RunStatistics@ stats) {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));
        UI::PushStyleVar(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(6, 2));

        if (UI::BeginTable("PlayersTable", 3, UI::TableFlags::SizingFixedFit | UI::TableFlags::Hideable | UI::TableFlags::ScrollY | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg | UI::TableFlags::PadOuterX)) {
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(tostring(stats.Settings.GoalMedal));
            UI::TableSetupColumn(tostring(Medals(stats.Settings.GoalMedal - 1)));
            UI::TableHeadersRow();

            UI::TableSetColumnEnabled(2, stats.Settings.GoalMedal != Medals::Bronze);

            UI::ListClipper clipper(stats.PlayerCounter.Length);

            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("Player" + i);

                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();

                    UI::Text(stats.PlayerCounter[i].Name);

                    UI::TableNextColumn();
                    UI::Text(tostring(stats.PlayerCounter[i].Count));

                    UI::TableNextColumn();
                    UI::Text(tostring(stats.PlayerCounter[i].SecondaryCount));

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::PopStyleVar();
        UI::PopStyleColor(2);
    }
}
