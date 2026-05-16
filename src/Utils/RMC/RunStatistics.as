class RunStatistics {
    RMC::GameMode Mode;
    int Timestamp;
    RunSettings@ Settings;
    array<MX::MapInfo@> Maps;
    array<MX::MapInfo@> FilteredMaps;
    array<array<string>> GeneralStats;

    // Medal stats
    int GoalCount;
    int BelowGoalCount;
    int FreeSkips;
    array<float> GoalMedalProgression;

    // Attempts
    int TotalAttempts = 0;
    array<float> Attempts;
    float AverageAttempts;
    int HighestAttempts;

    // Time
    float AverageTimeSpent;
    int TotalTime;
    array<float> Times;
    array<float> TotalTimeProgression;
    array<float> TimeEndsProgression;
    array<float> CompleteTimeProgression;

    // Timer
    array<float> TimerProgression;
    array<float> TimerEndProgression;
    array<float> CompleteTimerProgression;

    // Same arrays as above, but separated per result. Used for custom markers
    array<array<float>> TimerPerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> TimerEndPerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> TimePerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> AttemptsPerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> PacePerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> TimesPerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> MedalPerResult(RMC::MapResult::Broken_Skip, {});
    array<array<float>> MapCountPerResult(RMC::MapResult::Broken_Skip, {});

    // Counters
    Counter@ MapAuthorsCounter;
    Counter@ MapTagsCounter;
    Counter@ PlayerCounter;

    dictionary TotalTimePerTag;
    dictionary TotalTimePerAuthor;

    // Map milestones
    int Oneshots = 0;
    int InstaSkips = 0;
    array<int> ResultCounts(RMC::MapResult::Broken_Skip, 0);
    MX::MapInfo@ WorstMap;
    MX::MapInfo@ BestMap;
    MX::MapInfo@ ClosestNoMedal;
    MX::MapInfo@ ClosestMedal;
    MX::MapInfo@ ClosestCall;
    MX::MapInfo@ Overkill;

    // Graphs data
    array<int> Bins;
    array<string> BinNames;
    array<double> BinValues;
    array<string> ScatterNames;
    array<double> ScatterValues;
    array<string> TotalTimeNames;
    array<double> TotalTimeValues;
    array<string> TimerNames;
    array<double> TimerValues;

    // Pace
    array<float> PaceProgression;
    float HighestPace = 0;
    float LowestPace = 0;

    // Streaks
    int LongestMedalStreak = 0;
    int LongestNoMedalStreak = 0;
    int LongestTimeLossStreak = 0;

    RunStatistics(Json::Value@ json) {
        Log::Trace("[RunStatistics] Loading run statistics.");
        Log::Trace("[RunStatistics] JSON: " + Json::Write(json, true));

        GoalCount      = json["PrimaryCounterValue"];
        BelowGoalCount = json["SecondaryCounterValue"];
        FreeSkips      = json["FreeSkipsUsed"];
        TotalTime      = json["TotalTime"];
        @Settings      = RunSettings(json["Settings"]);
        Timestamp      = json.Get("PlayedAt", Time::Stamp);
        Mode           = RMC::GameMode(int(json["GameMode"]));

        array<string> allAuthors;
        array<string> allTags;
        array<string> medalPlayers;
        array<string> belowMedalPlayers;

        int medals = 0;
        int time = 0;

        int medalStreak = 0;
        int noMedalStreak = 0;
        int timeLossStreak = 0;

        for (uint i = 0; i < json["PlayedMaps"].Length; i++) {
            MX::MapInfo@ map = MX::MapInfo(json["PlayedMaps"][i]);

            if (map.Result == RMC::MapResult::None || map.Result == RMC::MapResult::Force_Switch || map.Result == RMC::MapResult::Broken_Skip) {
                continue;
            }

            Maps.InsertLast(map);

            if (map.Result == RMC::MapResult::Medal) {
                medals++;

                LongestNoMedalStreak = Math::Max(noMedalStreak, LongestNoMedalStreak);
                medalStreak++;
                noMedalStreak = 0;

                if (map.Attempts == 1) {
                    Oneshots++;
                }

                int delta = Math::Abs(map.GoalTime - map.SessionPB);

                if (ClosestMedal is null) {
                    @ClosestMedal = map;
                } else {
                    int oldDelta = Math::Abs(ClosestMedal.GoalTime - ClosestMedal.SessionPB);

                    if (delta < oldDelta) {
                        @ClosestMedal = map;
                    }
                }

                if (Overkill is null) {
                    @Overkill = map;
                } else {
                    int oldDelta = Math::Abs(Overkill.GoalTime - Overkill.SessionPB);

                    if (delta > oldDelta) {
                        @Overkill = map;
                    }
                }

                if (BestMap is null || BestMap.TimeSpent > map.TimeSpent) {
                    @BestMap = map;
                }

                if (Mode == RMC::GameMode::Survival) {
                    if (map.TimeSpent > Settings.RMS_TimeBack * 60 * 1000) {
                        timeLossStreak++;
                    } else {
                        LongestTimeLossStreak = Math::Max(timeLossStreak, LongestTimeLossStreak);
                        timeLossStreak = 0;
                    }

                    int timeLeft = map.TimerStart - map.TimeSpent;

                    // Only close call if there were 2 mins or fewer remaining
                    if (timeLeft <= 2 * 60 * 1000) {
                        if (ClosestCall is null || timeLeft < ClosestCall.TimerStart - ClosestCall.TimeSpent) {
                            @ClosestCall = map;
                        }
                    }
                }

#if TMNEXT
                if (Mode == RMC::GameMode::Together) {
                    medalPlayers.InsertLast(map.PlayerName);
                }
#endif
            } else {
                LongestMedalStreak = Math::Max(medalStreak, LongestMedalStreak);
                noMedalStreak++;
                medalStreak = 0;

                if (map.SessionPB > -1) {
                    int delta = Math::Abs(map.SessionPB - map.GoalTime);

                    if (ClosestNoMedal is null) {
                        @ClosestNoMedal = map;
                    } else {
                        int oldDelta = Math::Abs(ClosestNoMedal.SessionPB - ClosestNoMedal.GoalTime);

                        if (delta < oldDelta) {
                            @ClosestNoMedal = map;
                        }
                    }
                }

                if (Mode == RMC::GameMode::Survival) {
                    timeLossStreak++;

                    if (map.Attempts == 1 && map.Result == RMC::MapResult::Skip) {
                        InstaSkips++;
                    }
                }

#if TMNEXT
                if (Mode == RMC::GameMode::Together && map.Result == RMC::MapResult::Below_Medal) {
                    belowMedalPlayers.InsertLast(map.PlayerName);
                }
#endif
            }

            ResultCounts[map.Result]++;

            TotalAttempts += map.Attempts;
            Attempts.InsertLast(map.Attempts);
            AttemptsPerResult[map.Result].InsertLast(map.Attempts);
            HighestAttempts = Math::Max(map.Attempts, HighestAttempts);
            Times.InsertLast(float(map.TimeSpent) / 60 / 1000);

            allAuthors.InsertLast(map.Username);

            int64 authorTime = 0;

            if (TotalTimePerAuthor.Exists(map.Username)) {
                TotalTimePerAuthor.Get(map.Username, authorTime);
            }

            TotalTimePerAuthor.Set(map.Username, authorTime + map.TimeSpent);

            for (uint t = 0; t < map.Tags.Length; t++) {
                allTags.InsertLast(map.Tags[t].Name);

                int64 tagTime = 0;

                if (TotalTimePerTag.Exists(map.Tags[t].Name)) {
                    TotalTimePerTag.Get(map.Tags[t].Name, tagTime);
                }

                TotalTimePerTag.Set(map.Tags[t].Name, tagTime + map.TimeSpent);
            }

            CompleteTimeProgression.InsertLast(float(time) / 60 / 1000);
            CompleteTimerProgression.InsertLast(float(map.TimerStart) / 60 / 1000);
            time += map.TimeSpent;

            float sofar = float(time) / 60 / 1000;
            float pace = float(Settings.MaxTimer) * medals / sofar;

            PaceProgression.InsertLast(pace);
            TotalTimeProgression.InsertLast(sofar);
            TimerProgression.InsertLast(float(map.TimerStart - map.TimeSpent) / 60 / 1000);
            TimerEndProgression.InsertLast(float(map.TimerEnd) / 60 / 1000);

            PacePerResult[map.Result].InsertLast(pace);
            TimePerResult[map.Result].InsertLast(sofar);
            TimerPerResult[map.Result].InsertLast(float(map.TimerStart - map.TimeSpent) / 60 / 1000);
            TimerEndPerResult[map.Result].InsertLast(float(map.TimerEnd) / 60 / 1000);
            TimesPerResult[map.Result].InsertLast(float(map.TimeSpent) / 60 / 1000);
            MapCountPerResult[map.Result].InsertLast(Maps.Length);

            CompleteTimerProgression.InsertLast(float(map.TimerStart - map.TimeSpent) / 60 / 1000);
            CompleteTimeProgression.InsertLast(sofar);

            GoalMedalProgression.InsertLast(medals);
            MedalPerResult[map.Result].InsertLast(medals);

            if (WorstMap is null || map.TimeSpent > WorstMap.TimeSpent) {
                @WorstMap = map;
            }

            HighestPace = Math::Max(HighestPace, pace);

            if (pace > 0) {
                if (LowestPace == 0) {
                    LowestPace = pace;
                } else {
                    LowestPace = Math::Min(LowestPace, pace);
                }
            }
        }

        LongestNoMedalStreak = Math::Max(noMedalStreak, LongestNoMedalStreak);
        LongestMedalStreak = Math::Max(medalStreak, LongestMedalStreak);
        LongestTimeLossStreak = Math::Max(timeLossStreak, LongestTimeLossStreak);

        AverageTimeSpent = float(TotalTime) / float(Maps.Length);
        AverageAttempts = float(TotalAttempts) / float(Maps.Length);

        int binCount = Plots::GetBinCount(HighestAttempts, 5, 1);

        Bins.Resize(binCount);

        for (uint i = 0; i < Attempts.Length; i++) {
            // Attempts bins are offset by 1 and right inclusive (1-5), so substract 1 to include it in the previous bin
            // otherwise e.g. 5 would go to the bin (6-10)
            int index = int((Attempts[i] - 1) / 5);

            Bins[index]++;
        }

        BinValues = Plots::GetBinValues(Bins.Length, 5, 1);
        BinNames = Plots::GetBinNames(Bins.Length, 5, 1);

        if (WorstMap !is null) {
            ScatterValues = Plots::GetTickValues(WorstMap.TimeSpent, 60000);
            ScatterNames = Plots::FormatTickValues(ScatterValues);
        }

        TotalTimeValues = Plots::GetTickValues(TotalTime, 600000, 10);
        TotalTimeNames = Plots::FormatTickValues(TotalTimeValues);

        TimerValues = Plots::GetTickValues(TotalTime, 300000, 5);
        TimerNames = Plots::FormatTickValues(TimerValues);

        @MapAuthorsCounter = Counter(allAuthors);
        @MapTagsCounter = Counter(allTags);

#if TMNEXT
        if (Mode == RMC::GameMode::Together) {
            @PlayerCounter = Counter(medalPlayers, belowMedalPlayers);
        }
#endif

        FilteredMaps = Maps;

        CreateGeneralStats();

        Log::Trace("Finished loading run statistics.");
    }

    void Filter(RMC::MapResult result, string _search) {
        FilteredMaps.RemoveRange(0, FilteredMaps.Length);
        _search = _search.ToLower();

        if (result == RMC::MapResult::None && _search == "") {
            FilteredMaps = Maps;
            return;
        }

        for (uint i = 0; i < Maps.Length; i++) {
            if (Maps[i].Result == result || result == RMC::MapResult::None) {
                if (Maps[i].Name.ToLower().Contains(_search) || Maps[i].Username.ToLower().Contains(_search)) {
                    FilteredMaps.InsertLast(Maps[i]);
                }
            }
        }
    }

    void CreateGeneralStats() {
        GeneralStats.InsertLast({ "Maps Played", tostring(Maps.Length), "" });

        GeneralStats.InsertLast({ "Total Attempts", tostring(TotalAttempts), "" });

        if (MapAuthorsCounter.Length > 0) {
            CounterValue@ mapper = MapAuthorsCounter[0];
            GeneralStats.InsertLast({ "Most Frequent Mapper", mapper.Name, tostring(mapper.Count) + " " + Pluralize("map", mapper.Count) });
        } else {
            GeneralStats.InsertLast({ "Most Frequent Mapper", "None", "" });
        }

        if (MapTagsCounter.Length > 0) {
            CounterValue@ tag = MapTagsCounter[0];
            GeneralStats.InsertLast({ "Most Frequent Tag", tag.Name, tostring(tag.Count) + " " + Pluralize("map", tag.Count) });
        } else {
            GeneralStats.InsertLast({ "Most Frequent Tag", "None", "" });
        }

        if (BestMap !is null) {
            GeneralStats.InsertLast({ "Best Map", BestMap.Name, "Time Spent: " + Time::Format(BestMap.TimeSpent) });
        } else {
            GeneralStats.InsertLast({ "Best Map", "None", "" });
        }

        if (WorstMap !is null && WorstMap != BestMap) {
            GeneralStats.InsertLast({ "Worst Map", WorstMap.Name, "Time Spent: " + Time::Format(WorstMap.TimeSpent)});
        } else {
            GeneralStats.InsertLast({ "Worst Map", "None", "" });
        }

        GeneralStats.InsertLast({ "Longest Medal Streak", tostring(LongestMedalStreak) + " " + Pluralize("map", LongestMedalStreak), "" });

        GeneralStats.InsertLast({ "Longest Medal Drought", tostring(LongestNoMedalStreak) + " " + Pluralize("map", LongestNoMedalStreak), "" });

        if (ClosestMedal !is null) {
            GeneralStats.InsertLast({ "Closest Call", ClosestMedal.Name, "Got it by " + UI::FormatDelta(ClosestMedal.GoalTime, ClosestMedal.SessionPB, ClosestMedal.Type) });
        } else {
            GeneralStats.InsertLast({ "Closest Call", "None", "" });
        }

        if (ClosestNoMedal !is null) {
            GeneralStats.InsertLast({ "Closest no medal", ClosestNoMedal.Name, "Missed by " + UI::FormatDelta(ClosestNoMedal.GoalTime, ClosestNoMedal.SessionPB, ClosestNoMedal.Type) });
        } else {
            GeneralStats.InsertLast({ "Closest no medal", "None", "" });
        }

        if (Overkill !is null) {
            GeneralStats.InsertLast({ "Overkill", Overkill.Name, "Got it by over " + UI::FormatDelta(Overkill.GoalTime, Overkill.SessionPB, Overkill.Type) });
        } else {
            GeneralStats.InsertLast({ "Overkill", "None", "" });
        }

        float oneshotPercentage = float(Oneshots) / float(Maps.Length) * 100;
        GeneralStats.InsertLast({ "Oneshots", tostring(Oneshots), Text::Format("%.2f", oneshotPercentage) + "% of maps were oneshots" });

        if (Mode == RMC::GameMode::Survival) {
            float skipPercentage = float(InstaSkips) / float(Maps.Length) * 100;
            GeneralStats.InsertLast({ "Instant skips", tostring(InstaSkips), Text::Format("%.2f", skipPercentage) + "% of maps were instantly skipped" });

            GeneralStats.InsertLast({ "Longest Time Loss Streak", tostring(LongestTimeLossStreak) + " " + Pluralize("map", LongestTimeLossStreak), "in a row losing time" });

            if (ClosestCall !is null) {
                GeneralStats.InsertLast({ "Brink of Death", Time::Format(ClosestCall.TimerStart - ClosestCall.TimeSpent), "left when achieved the medal" });
            }
        }
    }
}
