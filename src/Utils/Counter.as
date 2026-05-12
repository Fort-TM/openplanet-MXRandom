class Counter {
	array<CounterValue@> Values;
	dictionary ValuesDict;
	dictionary SecondaryValuesDict;
	array<string> ValuesArr;
	int Total = 0;
	array<int> Counts;

	Counter(array<string> values, array<string> secondaryValues = {}) {
		CountValues(values, secondaryValues);
	}

	void CountValues(array<string> values, array<string> secondaryValues = {}) {
        for (uint i = 0; i < values.Length; i++) {
            int count = 0;

			if (values[i] == "") {
				continue;
			}

            if (ValuesDict.Exists(values[i])) {
                ValuesDict.Get(values[i], count);
            }

            ValuesDict.Set(values[i], count + 1);
        }

        for (uint i = 0; i < secondaryValues.Length; i++) {
            int count = 0;

			if (secondaryValues[i] == "") {
				continue;
			}

            if (SecondaryValuesDict.Exists(secondaryValues[i])) {
                SecondaryValuesDict.Get(secondaryValues[i], count);
            }

            SecondaryValuesDict.Set(secondaryValues[i], count + 1);
        }

        array<string> keys = ValuesDict.GetKeys();
		array<string> secondaryKeys = SecondaryValuesDict.GetKeys();

		for (uint i = 0; i < secondaryKeys.Length; i++) {
			if (keys.Find(secondaryKeys[i]) == -1) {
				keys.InsertLast(secondaryKeys[i]);
			}
		}

        for (uint i = 0; i < keys.Length; i++) {
            int64 count = 0;
            ValuesDict.Get(keys[i], count);

			int64 secondaryCount = 0;
			SecondaryValuesDict.Get(keys[i], secondaryCount);

			if (count > 0 || secondaryCount > 0) {
            	Values.InsertLast(CounterValue(keys[i], count, secondaryCount));
				Total += count;
			}
        }

		if (Values.Length > 1) {
			Values.Sort(function(a, b) {
				if (a.Count == b.Count) {
					if (a.SecondaryCount == b.SecondaryCount) {
						return a.Name.ToLower() < b.Name.ToLower();
					}

					return a.SecondaryCount > b.SecondaryCount;
				}

				return a.Count > b.Count;
			});
		}

		for (uint i = 0; i < Values.Length; i++) {
			ValuesArr.InsertLast(Values[i].Name);
			Counts.InsertLast(Values[i].Count);
		}
	}

	int opIndex(const string &in name) {
		return int(ValuesDict[name]);
	}

	CounterValue@ opIndex(int i) {
		return Values[i];
	}

	uint get_Length() {
		return Values.Length;
	}

	array<string> GetKeys() {
		return ValuesArr;
	}
}

class CounterValue {
	string Name;
	int Count;
	int SecondaryCount;

	CounterValue(const string&in name, int count, int secCount = 0) {
		this.Name = name;
		this.Count = count;
		this.SecondaryCount = secCount;
	}
}
