import SwiftUI

struct GuidedCaptureView: View {
    @Binding var draft: CaptureDraft
    var onCancel: (() -> Void)? = nil
    var fillsAvailableSpace = false
    var save: () -> Void

    @State private var step = 0
    @State private var tagText = ""
    @State private var chooseDate = false
    @State private var date = Date().addingTimeInterval(86400)
    private let categories = ["General", "Reading", "Work", "Ideas", "Learning", "Personal"]

    init(draft: Binding<CaptureDraft>, onCancel: (() -> Void)? = nil, fillsAvailableSpace: Bool = false, save: @escaping () -> Void) {
        self._draft = draft
        self.onCancel = onCancel
        self.fillsAvailableSpace = fillsAvailableSpace
        self.save = save
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerView

            if fillsAvailableSpace && step == 0 {
                step0ContentView
                    .frame(maxHeight: .infinity, alignment: .top)
            } else if fillsAvailableSpace {
                ScrollView {
                    stepContent
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxHeight: .infinity)
            } else {
                stepContent
            }

            footerNavigation
        }
        .task(id: draft.url) {
            guard let text = draft.url, let url = URL(string: text) else { return }
            do {
                let metadata = try await LinkMetadataLoader.load(url)
                guard !Task.isCancelled, draft.url == text else { return }
                if draft.title.isEmpty || draft.title == url.host || draft.title == text {
                    draft.title = metadata.title ?? draft.title
                }
                if draft.summary.isEmpty {
                    draft.summary = metadata.description ?? ""
                }
                if let site = metadata.site, !site.isEmpty {
                    draft.siteName = site
                }
                if let img = metadata.image, !img.isEmpty {
                    draft.previewImageUrl = img
                }
                if !metadata.keywords.isEmpty && draft.tags.isEmpty {
                    draft.tags = Array(Set(metadata.keywords.map { $0.lowercased() })).sorted()
                    tagText = draft.tags.joined(separator: ", ")
                }
            } catch { /* Metadata is optional; manual saving stays available. */ }
        }
        .padding(fillsAvailableSpace ? 0 : 20)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fillsAvailableSpace ? Color.clear : Color(white: 18.0 / 255))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(fillsAvailableSpace ? 0 : 0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(fillsAvailableSpace ? 0 : 0.35), radius: 14, y: 8)
        )
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: step0ContentView
        case 1: step1TitleView
        case 2: step2CategoryView
        default: step3ReturnScheduleView
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == step ? LaterAIStyle.accent : (i < step ? LaterAIStyle.accent.opacity(0.5) : Color.white.opacity(0.16)))
                            .frame(height: 3.5)
                            .animation(.easeInOut(duration: 0.25), value: step)
                    }
                }

                Spacer()

                if let onCancel {
                    Button(action: onCancel) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back to AI")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(LaterAIStyle.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color(white: 26.0 / 255), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("GUIDED CAPTURE • STEP \(step + 1) OF 4")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(LaterAIStyle.accent)
                .tracking(0.6)
        }
    }

    // MARK: - Step 0: Content
    private var step0ContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What would you like to save?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("Paste a link, note, quote, or draft content.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            ZStack(alignment: .topLeading) {
                if draft.content.isEmpty {
                    Text("Paste a link or write your content...")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $draft.content)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .tint(LaterAIStyle.accent)
                    .padding(8)
                    .frame(minHeight: 110, maxHeight: fillsAvailableSpace ? .infinity : 160)
            }
            .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            .accessibilityIdentifier("capture.content")

            if let detectedUrl = draft.url, !detectedUrl.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(LaterAIStyle.accent)
                    Text("Web link detected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(LaterAIStyle.accent)
                    Spacer()
                    if let host = URL(string: detectedUrl)?.host {
                        Text(host.replacingOccurrences(of: "www.", with: ""))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Step 1: Title
    private var step1TitleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Give it a title")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("A clear title helps you find and remember this item.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("TITLE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)

                TextField("Title", text: $draft.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .tint(LaterAIStyle.accent)
                    .padding(12)
                    .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    .accessibilityIdentifier("capture.title")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES OR SUMMARY (OPTIONAL)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)

                TextField("Add context or key takeaways", text: $draft.summary, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .tint(LaterAIStyle.accent)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
    }

    // MARK: - Step 2: Category & Tags
    private var step2CategoryView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Format, Category & Tags")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("Organize this capture so you can filter it later.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("FORMAT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        formatPill(title: "Automatic", isSelected: draft.contentType.isEmpty) {
                            draft.contentType = ""
                        }
                        ForEach(ItemContentType.allCases, id: \.self) { type in
                            formatPill(title: type.rawValue.capitalized, icon: type.systemIcon, isSelected: draft.contentType == type.rawValue) {
                                draft.contentType = type.rawValue
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            formatPill(title: category, isSelected: draft.category == category) {
                                draft.category = category
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("TAGS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)

                TextField("Tags, separated by commas", text: $tagText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .tint(LaterAIStyle.accent)
                    .padding(12)
                    .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    .accessibilityIdentifier("capture.tags")

                if !suggestedTags.isEmpty {
                    HStack(spacing: 6) {
                        Text("Suggested:")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.5))
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button(action: {
                                let current = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                                if !current.contains(tag) {
                                    tagText += tagText.isEmpty ? tag : ", \(tag)"
                                }
                            }) {
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(LaterAIStyle.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(white: 26.0 / 255), in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func formatPill(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? LaterAIStyle.accent : Color(white: 26.0 / 255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Return Schedule
    private var step3ReturnScheduleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("When do you want to see it again?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("Set a reminder date or save to your inbox for later.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            VStack(spacing: 8) {
                scheduleChoiceRow(
                    title: "Tomorrow",
                    subtitle: "9:00 AM",
                    icon: "calendar.badge.clock",
                    isSelected: draft.returnAt != nil && !chooseDate && Calendar.current.isDateInTomorrow(draft.returnAt ?? Date())
                ) {
                    chooseDate = false
                    draft.returnAt = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date().addingTimeInterval(86400))
                }

                scheduleChoiceRow(
                    title: "This Weekend",
                    subtitle: "Saturday morning",
                    icon: "sun.max.fill",
                    isSelected: draft.returnAt != nil && !chooseDate && Calendar.current.component(.weekday, from: draft.returnAt ?? Date()) == 7
                ) {
                    chooseDate = false
                    draft.returnAt = CaptureDraft.weekend()
                }

                scheduleChoiceRow(
                    title: "Next Week",
                    subtitle: "7 days from now",
                    icon: "calendar",
                    isSelected: draft.returnAt != nil && !chooseDate && (draft.returnAt?.timeIntervalSinceNow ?? 0) > 86400 * 5
                ) {
                    chooseDate = false
                    draft.returnAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                }

                scheduleChoiceRow(
                    title: "No Reminder",
                    subtitle: "Keep in inbox",
                    icon: "tray",
                    isSelected: draft.returnAt == nil && !chooseDate
                ) {
                    chooseDate = false
                    draft.returnAt = nil
                }

                scheduleChoiceRow(
                    title: "Choose Date",
                    subtitle: chooseDate && draft.returnAt != nil ? draft.returnAt!.formatted(date: .abbreviated, time: .shortened) : "Custom date & time",
                    icon: "slider.horizontal.3",
                    isSelected: chooseDate
                ) {
                    chooseDate.toggle()
                    if chooseDate { draft.returnAt = date }
                }
            }

            if chooseDate {
                CaptureDateChoices(date: $date)
                    .onChange(of: date) { _, value in
                        draft.returnAt = value
                    }
                    .padding(.top, 4)
            }

            if let selected = draft.returnAt {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 11))
                        .foregroundColor(LaterAIStyle.accent)
                    Text("Returns: \(selected.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func scheduleChoiceRow(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .black : LaterAIStyle.accent)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.black.opacity(0.15) : Color(white: 28.0 / 255), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? Color.black.opacity(0.7) : Color.white.opacity(0.55))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(LaterAIStyle.accent) : AnyShapeStyle(Color(white: 24.0 / 255)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Color.black.opacity(0.12) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer Navigation
    private var footerNavigation: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        step -= 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(white: 26.0 / 255), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(action: {
                if step == 0 {
                    let inferred = CaptureDraft.manual(draft.content)
                    if draft.title.isEmpty { draft.title = inferred.title }
                    if draft.tags.isEmpty { draft.tags = inferred.tags }
                    tagText = draft.tags.joined(separator: ", ")
                }
                if step == 2 {
                    draft.tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                if step == 3 {
                    save()
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        step += 1
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Text(step == 3 ? "Save to Vault" : "Continue")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: step == 3 ? "checkmark" : "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : LaterAIStyle.accent)
                )
            }
            .buttonStyle(.plain)
            .disabled(draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 4)
    }

    private var suggestedTags: [String] {
        let text = draft.content.lowercased()
        return ["design", "work", "recipe", "travel", "code", "music"].filter { text.contains($0) }.prefix(3).map { $0 }
    }
}
