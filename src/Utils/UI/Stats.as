namespace UI {
	void RenderStat(const string &in header, const string &in mainText, const string &in footer = "") {
		vec2 region = UI::GetWindowSize();

		UI::BeginChild(header, vec2(0), UI::ChildFlags::AutoResizeX | UI::ChildFlags::AutoResizeY | UI::ChildFlags::AlwaysAutoResize);

		UI::PushFontSize(27);
		UI::TextDisabled(header);
		UI::PopFontSize();

		UI::Indent(6);
		UI::PushFontSize(50);
		UI::Text(UI::TextEllipsis(mainText, region.x * .45));
		UI::PopFontSize();

		if (footer != "") {
			UI::PushFontSize(20);
			UI::TextDisabled(footer);
			UI::PopFontSize();
		}

		UI::Unindent(6);
		UI::EndChild();
	}

	void RenderCenteredStat(const string &in header, const string &in mainText, const string &in footer = "") {
		UI::SameLine();
		UI::CenterAlign();

		RenderStat(header, mainText, footer);
	}
}
