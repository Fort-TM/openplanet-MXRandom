namespace Plots {
    const uint LINE_WIDTH        = 5;
    const vec4 LINE_COLOR        = vec4(0.17, 0.63, 0.37, 1);
    const vec4 BASE_MARKER_COLOR = vec4(0.6, 0.85, 0.78, 1);
    const vec4 MARKER_OUTLINE    = vec4(0, 0, 0, .9);

    [Setting hidden]
    int MarkersSize = 8;

    [Setting hidden]
    bool DisplayMarkers = true;

    [Setting hidden]
    bool ResultsMarkers = true;

    void RenderSettings(bool toggleMarkers = true) {
        if (toggleMarkers) {
            DisplayMarkers = UI::Checkbox("Display markers", DisplayMarkers);

            UI::SameLine();
            UI::Separator(UI::SeparatorFlags::Vertical);
            UI::SameLine();
        }

        UI::BeginDisabled(toggleMarkers && !DisplayMarkers);

        UI::SetItemText("Markers size", 200);
        MarkersSize = UI::InputInt("##MarkerSie", MarkersSize);
        MarkersSize = Math::Clamp(MarkersSize, 1, 30);

        UI::SameLine();
        UI::Separator(UI::SeparatorFlags::Vertical);
        UI::SameLine();

        ResultsMarkers = UI::Checkbox("Result markers", ResultsMarkers);
        UI::SetItemTooltip("Display different markers for each map result");

        UI::EndDisabled();
    }

    void RenderResultsMarkers(array<array<float>> xValues, array<array<float>> yValues, Medals goalMedal) {
        for (uint i = 0; i < xValues.Length; i++) {
            if (xValues[i].IsEmpty()) {
                continue;
            }

            RMC::MapResult result = RMC::MapResult(i);

            SetMarkerResultStyle(result, goalMedal);
            UI::Plot::PlotScatter("##Scatter" + tostring(result), xValues[i], yValues[i]);
        }
    }

    vec4 GetResultColor(RMC::MapResult res, Medals goalMedal) {
        switch (res) {
            case RMC::MapResult::Medal:
                return UI::GetMedalColor(goalMedal);
            case RMC::MapResult::Below_Medal:
                return UI::GetMedalColor(Medals(goalMedal - 1));
            case RMC::MapResult::Skip:
            case RMC::MapResult::Free_Skip:
                // Each result is for different modes, so it's fine to use the same color
                return vec4(1, .25, .3, 1);
            case RMC::MapResult::Timer:
                return vec4(.5, .5, .5, 1);
            case RMC::MapResult::None:
            case RMC::MapResult::Broken_Skip:
            default:
                return vec4(1);
        }
    }

    void SetMarkerResultStyle(RMC::MapResult res, Medals goalMedal) {
        UI::Plot::Marker marker = UI::Plot::Marker::Square;
        int weight = -1;
        vec4 outline = MARKER_OUTLINE;
        vec4 color = GetResultColor(res, goalMedal);

        if (res != RMC::MapResult::Medal && res != RMC::MapResult::Below_Medal) {
            marker = UI::Plot::Marker::Cross;
            weight = 3;
            outline = color; // cross can't be filled, so we use the outline for it
        }

        UI::Plot::SetNextMarkerStyle(marker, MarkersSize, color, weight, outline);
    }

    // Plots

    void PacePlot(RunStatistics@ stats) {
        if (UI::Plot::BeginPlot("##Pace" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::NoMouseText)) {
            int axesFlags = UI::Plot::AxisFlags::NoHighlight;
            UI::Plot::SetupAxes("Time", "Pace", axesFlags, axesFlags);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -15, stats.Settings.MaxTimer + 15);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, stats.LowestPace - 10, stats.HighestPace + 10);

            UI::Plot::SetupAxesLimits(0, stats.Settings.MaxTimer + 5, stats.LowestPace - 5, stats.HighestPace + 5);
            UI::Plot::SetupAxisTicks(UI::Plot::Axis::X1, stats.TotalTimeValues, stats.TotalTimeNames);

            UI::Plot::SetNextLineStyle(LINE_COLOR, LINE_WIDTH);

            UI::PushFontSize(20);
            UI::Plot::PlotLine("##Pace", stats.TotalTimeProgression, stats.PaceProgression);
            UI::PopFontSize();

            if (DisplayMarkers) {
                if (ResultsMarkers) {
                    RenderResultsMarkers(stats.TimePerResult, stats.PacePerResult, stats.Settings.GoalMedal);
                } else {
                    UI::Plot::SetNextMarkerStyle(UI::Plot::Marker::Square, MarkersSize, BASE_MARKER_COLOR, -1, MARKER_OUTLINE);
                    UI::Plot::PlotScatter("##ScatterMarkers", stats.TotalTimeProgression, stats.PaceProgression);
                }

                if (UI::Plot::IsPlotHovered()) {
                    MarkerTooltip(stats.TotalTimeProgression, stats.PaceProgression, stats.Maps);
                }
            }

            UI::Plot::EndPlot();
        }
    }

    void AttemptsHistogramPlot(RunStatistics@ stats) {
        float end = Math::Ceil((float(stats.HighestAttempts) + 1) / 5) * 5;

        if (UI::Plot::BeginPlot("##AttemptsHistogram" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::CanvasOnly)) {
            UI::Plot::SetupAxes("Attempts", "Map count", UI::Plot::AxisFlags::NoHighlight | UI::Plot::AxisFlags::NoGridLines, UI::Plot::AxisFlags::NoHighlight);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -10, stats.HighestAttempts + 20);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, -10, stats.Maps.Length + 20);

            UI::Plot::SetupAxesLimits(-5, stats.HighestAttempts + 10, -2, stats.Maps.Length + 5);

            UI::Plot::SetupAxisTicks(UI::Plot::Axis::X1, stats.BinValues, stats.BinNames);

            UI::Plot::SetNextFillStyle(LINE_COLOR);

            UI::PushFontSize(20);
            UI::Plot::PlotHistogram("##RunHistogram", stats.Attempts, stats.Bins.Length, 1, 1, end + 1);
            UI::PopFontSize();

            if (UI::Plot::IsPlotHovered()) {
                HistogramTooltip(stats.Bins, 5, stats.Maps.Length, 1);
            }

            UI::Plot::EndPlot();
        }
    }

    void AttemptsScatterPlot(RunStatistics@ stats) {
        if (UI::Plot::BeginPlot("##AttemptsScatter" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::CanvasOnly)) {
            UI::Plot::SetupAxes("Time Spent", "Attempts", UI::Plot::AxisFlags::NoHighlight, UI::Plot::AxisFlags::NoHighlight);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -5, (stats.WorstMap.TimeSpent / 60 / 1000) + 5);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, -10, stats.HighestAttempts + 20);

            UI::Plot::SetupAxesLimits(0, (stats.WorstMap.TimeSpent / 60 / 1000) + 2, -2, stats.HighestAttempts + 10);

            UI::Plot::SetupAxisTicks(UI::Plot::Axis::X1, stats.ScatterValues, stats.ScatterNames);

            UI::PushFontSize(20);

            if (ResultsMarkers) {
                RenderResultsMarkers(stats.TimesPerResult, stats.AttemptsPerResult, stats.Settings.GoalMedal);
            } else {
                UI::Plot::SetNextMarkerStyle(UI::Plot::Marker::Square, MarkersSize, BASE_MARKER_COLOR, -1, MARKER_OUTLINE);
                UI::Plot::PlotScatter("##AttemptsMarkers", stats.Times, stats.Attempts);
            }

            UI::PopFontSize();

            if (UI::Plot::IsPlotHovered()) {
                MarkerTooltip(stats.Times, stats.Attempts, stats.Maps);
            }

            UI::Plot::EndPlot();
        }
    }

    void TimerProgressPlot(RunStatistics@ stats) {
        if (UI::Plot::BeginPlot("##TimerProgress" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::NoMouseText)) {
            UI::Plot::SetupAxes("Time", "Timer", UI::Plot::AxisFlags::NoHighlight, UI::Plot::AxisFlags::NoHighlight);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -5, (stats.TotalTime / 60 / 1000) + 15);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, -5, stats.Settings.MaxTimer + 15);

            UI::Plot::SetupAxesLimits(-5, (stats.TotalTime / 60 / 1000) + 5, -5, stats.Settings.MaxTimer + 5);
            UI::Plot::SetupAxisTicks(UI::Plot::Axis::X1, stats.TotalTimeValues, stats.TotalTimeNames);
            UI::Plot::SetupAxisTicks(UI::Plot::Axis::Y1, stats.TimerValues, stats.TimerNames);

            UI::Plot::SetNextLineStyle(LINE_COLOR, LINE_WIDTH);

            UI::PushFontSize(20);

            UI::Plot::PlotLine("##TimerLine", stats.CompleteTimeProgression, stats.CompleteTimerProgression);

            UI::PopFontSize();

            if (DisplayMarkers) {
                if (ResultsMarkers) {
                    RenderResultsMarkers(stats.TimePerResult, stats.TimerPerResult, stats.Settings.GoalMedal);
                } else {
                    UI::Plot::SetNextMarkerStyle(UI::Plot::Marker::Square, MarkersSize, BASE_MARKER_COLOR, -1, MARKER_OUTLINE);
                    UI::Plot::PlotScatter("##ScatterMarkers", stats.TotalTimeProgression, stats.TimerProgression);
                }

                if (UI::Plot::IsPlotHovered()) {
                    MarkerTooltip(stats.TotalTimeProgression, stats.TimerProgression, stats.Maps);
                }
            }

            UI::Plot::EndPlot();
        }
    }

    void MedalsTimeline(RunStatistics@ stats) {
        if (UI::Plot::BeginPlot("##MedalsTimeline" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::NoMouseText)) {
            UI::Plot::SetupAxes("Time", tostring(stats.Settings.GoalMedal) + "s", UI::Plot::AxisFlags::NoHighlight, UI::Plot::AxisFlags::NoHighlight);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -5, (stats.TotalTime / 60 / 1000) + 15);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, -5, stats.GoalCount + 15);

            UI::Plot::SetupAxesLimits(-5, (stats.TotalTime / 60 / 1000) + 5, 0, stats.GoalCount + 5);
            UI::Plot::SetupAxisTicks(UI::Plot::Axis::X1, stats.TotalTimeValues, stats.TotalTimeNames);

            UI::Plot::SetNextLineStyle(LINE_COLOR, LINE_WIDTH);

            UI::PushFontSize(20);
            UI::Plot::PlotLine("##Timeline", stats.TotalTimeProgression, stats.GoalMedalProgression);
            UI::PopFontSize();

            if (DisplayMarkers) {
                if (ResultsMarkers) {
                    RenderResultsMarkers(stats.TimePerResult, stats.MedalPerResult, stats.Settings.GoalMedal);
                } else {
                    UI::Plot::SetNextMarkerStyle(UI::Plot::Marker::Square, MarkersSize, BASE_MARKER_COLOR, -1, MARKER_OUTLINE);
                    UI::Plot::PlotScatter("##ScatterMarkers", stats.TotalTimeProgression, stats.GoalMedalProgression);
                }

                if (UI::Plot::IsPlotHovered()) {
                    MarkerTooltip(stats.TotalTimeProgression, stats.GoalMedalProgression, stats.Maps);
                }
            }

            UI::Plot::EndPlot();
        }
    }

    void TimeGainLossPlot(RunStatistics@ stats) {
        if (UI::Plot::BeginPlot("##TimeGainLoss" + stats.Timestamp, vec2(-1), UI::Plot::PlotFlags::NoMenus | UI::Plot::PlotFlags::NoMouseText)) {
            UI::Plot::SetupAxes("Map", "Timer", UI::Plot::AxisFlags::NoHighlight, UI::Plot::AxisFlags::NoHighlight);

            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::X1, -5, stats.Maps.Length + 5);
            UI::Plot::SetupAxisLimitsConstraints(UI::Plot::Axis::Y1, -10, stats.Settings.MaxTimer + 15);

            UI::Plot::SetupAxesLimits(0, stats.Maps.Length + 2, -5, stats.Settings.MaxTimer + 5);
            UI::Plot::SetupAxisTicks(UI::Plot::Axis::Y1, stats.TimerValues, stats.TimerNames);

            UI::Plot::SetNextLineStyle(LINE_COLOR, LINE_WIDTH);

            UI::PushFontSize(20);
            UI::Plot::PlotLine("##TimeGainLine", stats.TimerEndProgression, 1, 1);
            UI::PopFontSize();

            if (DisplayMarkers) {
                if (ResultsMarkers) {
                    RenderResultsMarkers(stats.MapCountPerResult, stats.TimerEndPerResult, stats.Settings.GoalMedal);
                } else {
                    UI::Plot::SetNextMarkerStyle(UI::Plot::Marker::Square, MarkersSize, BASE_MARKER_COLOR, -1, MARKER_OUTLINE);
                    UI::Plot::PlotScatter("##ScatterMarkers", stats.TimerEndProgression, 1, 1);
                }

                if (UI::Plot::IsPlotHovered()) {
                    MarkerTooltip(stats.TimerEndProgression, stats.Maps, 1);
                }
            }

            UI::Plot::EndPlot();
        }
    }

    // Tooltips

    void HistogramTooltip(array<int> bins, int binSize, int total, int min = 0) {
        vec2 pos = UI::Plot::GetPlotMousePos();

        if (pos.x < min || pos.y < 0) {
            return;
        }

        int index = int(Math::Floor((pos.x - min) / binSize));

        if (index >= int(bins.Length) || index < 0) {
            return;
        }

        int mapCount = bins[index];

        if (mapCount == 0) {
            return;
        }

        if (pos.y <= float(mapCount)) {
            string attemptsStr = tostring((index * binSize) + min) + "-" + tostring((index * binSize) + binSize);
            string percentageStr = Text::Format("%.2f", float(mapCount) / float(total) * 100);

            UI::BeginTooltip();

            UI::Text(tostring(mapCount) + " " + Pluralize("map", mapCount) + " (" + percentageStr + "%) required " + attemptsStr + " attempts.");

            UI::EndTooltip();
        }
    }

    void MarkerTooltip(array<float> xValues, array<float> yValues, array<MX::MapInfo@> maps) {
        for (uint i = 0; i < xValues.Length; i++) {
            vec2 pos = UI::Plot::PlotToPixels(xValues[i], yValues[i]);

            if (UI::IsMouseHoveringRect(pos - vec2(MarkersSize), pos + vec2(MarkersSize))) {
                MapStatsTooltip(maps[i]);
                return;
            }
        }
    }

    void MarkerTooltip(array<float> yValues, array<MX::MapInfo@> maps, int xOffset = 0) {
        for (uint i = 0; i < yValues.Length; i++) {
            vec2 pos = UI::Plot::PlotToPixels(i + xOffset, yValues[i]);

            if (UI::IsMouseHoveringRect(pos - vec2(MarkersSize), pos + vec2(MarkersSize))) {
                MapStatsTooltip(maps[i]);
                return;
            }
        }
    }

    void MapStatsTooltip(MX::MapInfo@ map) {
        UI::BeginTooltip();

        CachedImage@ mapThumb = Images::CachedFromURL(MX_URL + "/mapimage/" + map.MapId + "/1?hq=true");

        if (mapThumb.m_texture !is null) {
            vec2 thumbSize = mapThumb.m_texture.GetSize();
            float proportion = thumbSize.x / 200;

            UI::Image(mapThumb.m_texture, thumbSize / proportion);
        } else if (!mapThumb.m_error) {
            UI::Text(Icons::AnimatedHourglass + " Loading");
        } else if (mapThumb.m_notFound) {
            UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$ Thumbnail not found.");
        } else {
            UI::Text("\\$f00" + Icons::Times + "\\$z Error loading thumbnail.");
        }

        UI::TextWrapped(Text::OpenplanetFormatCodes(map.GbxMapName));
        UI::TextDisabled("by " + map.Username);

        UI::Separator();

        UI::Text("Time spent: " + Time::Format(map.TimeSpent));
        UI::Text("Attempts: " + map.Attempts);
        UI::Text("Result: " + tostring(map.Result).Replace("_", " "));

        UI::EndTooltip();
    }

    // Helpers

	array<double> GetTickValues(uint maxValue, uint cutoff, uint multiplier = 1) {
		uint nextCutoff = ((maxValue + cutoff - 1) / cutoff) * cutoff;
		uint count = nextCutoff / cutoff;

		array<double> values;

		for (uint i = 0; i <= count; i++) {
			values.InsertLast(i * multiplier);
		}

		return values;
	}

	array<string> FormatTickValues(array<double> values, uint multiplier = 60000) {
		array<string> formattedValues;

		for (uint i = 0; i < values.Length; i++) {
			formattedValues.InsertLast(Time::Format(uint(values[i]) * multiplier, false));
		}

		return formattedValues;
	}

	int GetBinCount(uint max, uint binSize, uint offset = 0) {
        float end = Math::Ceil((float(max) + offset) / binSize) * binSize;

        return int(end / binSize);
	}

    array<double> GetBinValues(uint binCount, uint binSize, uint offset = 0) {
        array<double> values;

        for (uint i = 0; i < binCount; i++) {
            values.InsertLast((i * binSize) + (float(binSize) / 2) + offset);
        }

        return values;
    }

    array<string> GetBinNames(uint binCount, uint binSize, uint offset = 0) {
        array<string> binNames;

        for (uint i = 0; i < binCount; i++) {
            string name = tostring((i * binSize) + offset) + "-" + tostring((i + 1) * binSize);
            binNames.InsertLast(name);
        }

        return binNames;
    }
}
