import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import SwiftData

struct GuidedCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LBCollection.name) private var collections: [LBCollection]

    @Binding var draft: CaptureDraft
    var onCancel: (() -> Void)? = nil
    var fillsAvailableSpace = false
    var save: () -> Void

    @State private var step = 0
    @State private var tagInput = ""
    @State private var showingNewCollectionInput = false
    @State private var newCollectionName = ""
    @State private var chooseDate = false
    @State private var date = Date().addingTimeInterval(86400)

    // Attachments state
    private enum AttachmentMode {
        case attach
        case saveOnly
    }
    @State private var attachmentMode: AttachmentMode = .attach
    @State private var showingFilePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    init(draft: Binding<CaptureDraft>, onCancel: (() -> Void)? = nil, fillsAvailableSpace: Bool = false, save: @escaping () -> Void) {
        self._draft = draft
        self.onCancel = onCancel
        self.fillsAvailableSpace = fillsAvailableSpace
        self.save = save
    }

    private var canProceed: Bool {
        !draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !draft.attachments.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerView

            if fillsAvailableSpace && (step == 0 || step == 1) {
                stepContent
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
                }
            } catch { /* Metadata is optional; manual saving stays available. */ }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentPick(result: result)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoPick(item: newItem)
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
        .preferredColorScheme(fillsAvailableSpace ? .dark : .light)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: step0ContentView
        case 1: step1TitleView
        case 2: step2CollectionAndTagsView
        default: step3ReturnScheduleView
        }
    }

    // MARK: - Header (No step indicators or badge text per user request)
    private var headerView: some View {
        HStack {
            Spacer()
            if let onCancel {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(6)
                        .background(Color(white: 26.0 / 255), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Step 0: Content ("Start typing here" and input only per user request)
    private var step0ContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start typing here")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            ZStack(alignment: .topLeading) {
                if draft.content.isEmpty {
                    Text("Start typing here...")
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
                    .frame(minHeight: 120, maxHeight: fillsAvailableSpace ? .infinity : 180)
            }
            .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            .accessibilityIdentifier("capture.content")

            // Attached Documents or Photos Pills
            if !draft.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(draft.attachments) { att in
                        HStack(spacing: 8) {
                            Image(systemName: att.typeIdentifier.contains("image") ? "photo.fill" : "doc.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(LaterAIStyle.accent)
                            Text(att.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                draft.attachments.removeAll { $0.id == att.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(white: 28.0 / 255), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

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

                ZStack(alignment: .topLeading) {
                    if draft.summary.isEmpty {
                        Text("Add context or key takeaways...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $draft.summary)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .tint(LaterAIStyle.accent)
                        .padding(8)
                        .frame(minHeight: 100, maxHeight: fillsAvailableSpace ? .infinity : 180)
                }
                .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                .frame(maxHeight: fillsAvailableSpace ? .infinity : nil)
            }
            .frame(maxHeight: fillsAvailableSpace ? .infinity : nil)
        }
        .frame(maxHeight: fillsAvailableSpace ? .infinity : nil, alignment: .top)
    }

    // MARK: - Step 2: Collection & Tags
    private var step2CollectionAndTagsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Format, Collection & Tags")
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
                HStack {
                    Text("COLLECTION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(0.5)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingNewCollectionInput.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingNewCollectionInput ? "xmark" : "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text(showingNewCollectionInput ? "Cancel" : "New Collection")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(LaterAIStyle.accent)
                    }
                    .buttonStyle(.plain)
                }

                if showingNewCollectionInput {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(LaterAIStyle.accent)
                            .font(.system(size: 14))

                        TextField("New collection name...", text: $newCollectionName)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .tint(LaterAIStyle.accent)
                            .onSubmit {
                                createNewCollection()
                            }

                        if !newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                createNewCollection()
                            } label: {
                                Text("Add")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(LaterAIStyle.accent, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(LaterAIStyle.accent.opacity(0.35), lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let isNoneSelected = (draft.collectionName == nil || draft.collectionName?.isEmpty == true) && (draft.category.isEmpty || draft.category.lowercased() == "none" || draft.category.lowercased() == "general")

                        formatPill(title: "None", icon: "tray", isSelected: isNoneSelected) {
                            draft.collectionName = nil
                            draft.category = ""
                        }

                        if let custom = draft.collectionName?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !custom.isEmpty,
                           !collections.contains(where: { $0.name.localizedCaseInsensitiveCompare(custom) == .orderedSame }) {
                            formatPill(title: custom, icon: "folder.fill", isSelected: true) {
                                draft.collectionName = custom
                                draft.category = custom
                            }
                        }

                        ForEach(collections) { coll in
                            let isSelected = (draft.collectionName?.localizedCaseInsensitiveCompare(coll.name) == .orderedSame) ||
                                             (draft.category.localizedCaseInsensitiveCompare(coll.name) == .orderedSame)
                            formatPill(title: coll.name, icon: coll.iconName, isSelected: isSelected) {
                                if isSelected {
                                    draft.collectionName = nil
                                    draft.category = ""
                                } else {
                                    draft.collectionName = coll.name
                                    draft.category = coll.name
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TAGS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(0.5)

                    Spacer()

                    if !draft.tags.isEmpty {
                        Text("\(draft.tags.count) marked")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }

                if !draft.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(draft.tags, id: \.self) { tag in
                                HStack(spacing: 5) {
                                    Text("#\(tag)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)

                                    Button {
                                        removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color.black.opacity(0.7))
                                            .padding(2)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Remove tag \(tag)")
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 8)
                                .padding(.vertical, 6)
                                .background(LaterAIStyle.accent, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.4))

                    TextField("Add tag (Enter or : to mark)", text: $tagInput)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .tint(LaterAIStyle.accent)
                        .accessibilityIdentifier("capture.tags")
                        .onSubmit {
                            commitCurrentTagInput()
                        }
                        .onChange(of: tagInput) { _, newValue in
                            handleTagInputChange(newValue)
                        }

                    if !tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            commitCurrentTagInput()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(LaterAIStyle.accent)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(white: 24.0 / 255), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))

                if !suggestedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Suggested:")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))

                            ForEach(suggestedTags, id: \.self) { tag in
                                let isAlreadyAdded = draft.tags.contains(where: { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame })
                                Button(action: {
                                    addTag(tag)
                                }) {
                                    HStack(spacing: 3) {
                                        Text("#\(tag)")
                                            .font(.system(size: 11, weight: .medium))
                                        if isAlreadyAdded {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(isAlreadyAdded ? Color.white.opacity(0.4) : LaterAIStyle.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(white: 26.0 / 255), in: Capsule())
                                    .overlay(Capsule().strokeBorder(isAlreadyAdded ? Color.white.opacity(0.06) : Color.white.opacity(0.1), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .disabled(isAlreadyAdded)
                            }
                        }
                        .padding(.top, 2)
                    }
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

    // MARK: - Footer Navigation (with + attachment options beside Continue)
    private var footerNavigation: some View {
        HStack(spacing: 10) {
            if step > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        step -= 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        if !fillsAvailableSpace {
                            Text("Back")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(white: 26.0 / 255), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // '+' Attachment Options Button
            attachmentMenuButton

            if !fillsAvailableSpace { Spacer() }

            // Continue / Save Button
            Button(action: {
                if step == 0 {
                    let inferred = CaptureDraft.manual(draft.content)
                    if draft.title.isEmpty {
                        draft.title = draft.attachments.first?.name ?? inferred.title
                    }
                    if draft.tags.isEmpty { draft.tags = inferred.tags }
                }
                if step == 2 {
                    commitCurrentTagInput()
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
                .frame(maxWidth: fillsAvailableSpace ? .infinity : nil)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: fillsAvailableSpace ? 24 : 14)
                        .fill(canProceed ? LaterAIStyle.accent : Color.gray.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
        }
        .padding(.top, 4)
    }

    // MARK: - Attachment Menu Button (+ icon)
    private var attachmentMenuButton: some View {
        Menu {
            Section("Attach to Item") {
                Button {
                    attachmentMode = .attach
                    showingFilePicker = true
                } label: {
                    Label("Attach Document", systemImage: "doc.fill")
                }

                Button {
                    attachmentMode = .attach
                    showingPhotoPicker = true
                } label: {
                    Label("Attach Photo", systemImage: "photo.fill")
                }
            }

            Section("Save Attachments Only") {
                Button {
                    attachmentMode = .saveOnly
                    showingFilePicker = true
                } label: {
                    Label("Save Document Only", systemImage: "arrow.down.doc.fill")
                }

                Button {
                    attachmentMode = .saveOnly
                    showingPhotoPicker = true
                } label: {
                    Label("Save Photo Only", systemImage: "arrow.down.circle.fill")
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(white: 26.0 / 255), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Handlers for Attachments
    private func handleDocumentPick(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let sourceURL = urls.first else { return }
        do {
            let ext = sourceURL.pathExtension.lowercased()
            let utType = UTType(filenameExtension: ext)?.identifier ?? "public.item"
            let attachment = try SharedCaptureStore.copyFile(sourceURL, type: utType)

            if attachmentMode == .saveOnly {
                draft.attachments = [attachment]
                if draft.title.isEmpty { draft.title = attachment.name }
                if draft.content.isEmpty { draft.content = attachment.name }
                save()
            } else {
                draft.attachments.append(attachment)
                if draft.title.isEmpty { draft.title = attachment.name }
            }
            LBHaptic.medium()
        } catch {
            print("Failed to attach document: \(error.localizedDescription)")
        }
    }

    private func handlePhotoPick(item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let filename = "photo-\(UUID().uuidString.prefix(8)).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: tempURL)
            do {
                let attachment = try SharedCaptureStore.copyFile(tempURL, type: "public.jpeg")
                try? FileManager.default.removeItem(at: tempURL)

                await MainActor.run {
                    if attachmentMode == .saveOnly {
                        draft.attachments = [attachment]
                        if draft.title.isEmpty { draft.title = attachment.name }
                        if draft.content.isEmpty { draft.content = attachment.name }
                        save()
                    } else {
                        draft.attachments.append(attachment)
                        if draft.title.isEmpty { draft.title = attachment.name }
                    }
                    selectedPhotoItem = nil
                    LBHaptic.medium()
                }
            } catch {
                print("Failed to attach photo: \(error.localizedDescription)")
            }
        }
    }

    private var suggestedTags: [String] {
        let text = draft.content.lowercased()
        return ["design", "work", "recipe", "travel", "code", "music"].filter { text.contains($0) }.prefix(3).map { $0 }
    }

    private func createNewCollection() {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft.collectionName = trimmed
        draft.category = trimmed
        _ = SyncCoordinator.shared.ensureCollectionExists(named: trimmed, context: modelContext)
        newCollectionName = ""
        withAnimation(.easeInOut(duration: 0.2)) {
            showingNewCollectionInput = false
        }
        LBHaptic.medium()
    }

    private func handleTagInputChange(_ value: String) {
        if value.contains(":") || value.contains(",") {
            let parts = value.components(separatedBy: CharacterSet(charactersIn: ":,"))
            for part in parts.dropLast() {
                addTag(part)
            }
            tagInput = parts.last ?? ""
        }
    }

    private func commitCurrentTagInput() {
        let clean = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if !clean.isEmpty {
            addTag(clean)
            tagInput = ""
        }
    }

    private func addTag(_ raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard !clean.isEmpty else { return }
        if !draft.tags.contains(where: { $0.localizedCaseInsensitiveCompare(clean) == .orderedSame }) {
            withAnimation(.easeInOut(duration: 0.18)) {
                draft.tags.append(clean)
            }
            LBHaptic.light()
        }
    }

    private func removeTag(_ tag: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            draft.tags.removeAll { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }
        }
        LBHaptic.light()
    }
}
