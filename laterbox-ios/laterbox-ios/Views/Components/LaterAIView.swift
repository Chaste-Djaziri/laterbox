//
//  LaterAIView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import SwiftData

public struct LaterAIMessage: Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public let isUser: Bool
    public let timestamp: Date

    public init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

public struct LaterAIView: View {
    @Binding var isPresented: Bool
    @Binding var progress: CGFloat
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [LBItem]

    @State private var inputText: String = ""
    @StateObject private var conversation = LaterAIConversation()
    @State private var editingItem: LBItem?
    @State private var chooseReturnDate = false
    @State private var selectedReturnDate = Date().addingTimeInterval(86400)
    private var messages: [LaterAIMessage] { conversation.messages }
    private var isThinking: Bool { conversation.thinking }
    @FocusState private var isInputFocused: Bool

    // Suggested quick prompts like ChatGPT mobile
    private let promptSuggestions = [
        "Summarize my unsorted inbox",
        "Which items have return dates this week?",
        "Find saved articles and guides",
        "Help me clean up old bookmarks"
    ]

    public init(isPresented: Binding<Bool>, progress: Binding<CGFloat>) {
        self._isPresented = isPresented
        self._progress = progress
    }

    public var body: some View {
        let clampedProgress = max(0.0, min(1.0, progress))
        let travelFactor = (1.0 - clampedProgress)

        VStack(spacing: 10) {
            topBar

            if conversation.manual {
                GuidedCaptureView(draft: $conversation.draft, fillsAvailableSpace: true) {
                    conversation.save(context: modelContext)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            messageListView
                            if !conversation.results.isEmpty { matchedResultsView }
                            if let error = conversation.error { errorRetryView(error) }
                            if isThinking { thinkingIndicatorView }
                            if let title = optionsTitle {
                                Text(title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            ForEach(activeOptions) { option in
                                Button(action: option.action) {
                                    HStack(spacing: 12) {
                                        if let icon = option.icon {
                                            Image(systemName: icon).foregroundStyle(LaterAIStyle.accent)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(option.title).font(.system(size: 14, weight: .semibold))
                                            if let subtitle = option.subtitle {
                                                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.6))
                                            }
                                        }
                                        Spacer()
                                    }
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(Color(hex: "1C1C1E"), in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                            Color.clear.frame(height: 1).id("bottomAnchor")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottomAnchor", anchor: .bottom) }
                    }
                    .onChange(of: isThinking) { _, _ in
                        withAnimation { proxy.scrollTo("bottomAnchor", anchor: .bottom) }
                    }
                }
                .frame(maxHeight: .infinity)

                if conversation.savedItem == nil {
                    bottomChatInputBar
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0C0C0D").ignoresSafeArea())
        .preferredColorScheme(.light)
        .offset(y: travelFactor * -160)
        .opacity(clampedProgress)
        .onAppear {
            if let prompt = LaterAIManager.shared.initialPrompt {
                triggerInitialPrompt(prompt)
            } else if let subject = LaterAIManager.shared.attachedSubject, inputText.isEmpty {
                inputText = subject
            }
        }
        .onReceive(LaterAIManager.shared.$initialPrompt) { prompt in
            if let prompt, !prompt.isEmpty {
                triggerInitialPrompt(prompt)
            }
        }
        .onDisappear {
            conversation.reset()
            LaterAIManager.shared.attachedSubject = nil
            LaterAIManager.shared.initialPrompt = nil
        }
        .sheet(item: $editingItem) { item in
            NavigationStack { ItemDetailView(item: item) }
        }
        .sheet(isPresented: $chooseReturnDate) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker(
                        "Return Date",
                        selection: $selectedReturnDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(LaterAIStyle.accent)
                    .environment(\.colorScheme, .light)
                    .padding()
                    .background(Color(white: 20.0/255), in: RoundedRectangle(cornerRadius: 16))

                    Button(action: {
                        chooseReturnDate = false
                        let formatted = selectedReturnDate.formatted(date: .abbreviated, time: .shortened)
                        sendOptionReply(formatted) {
                            conversation.schedule(selectedReturnDate, context: modelContext)
                        }
                    }) {
                        Text("Confirm Return Date")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LaterAIStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(20)
                .background(Color.black.ignoresSafeArea())
                .navigationTitle("Select Return Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { chooseReturnDate = false }
                            .foregroundColor(LaterAIStyle.accent)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Top Header Bar
    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(Color(hex: "38383A"))
                .frame(width: 38, height: 4)
                .frame(maxWidth: .infinity)
            HStack {
                HStack(spacing: 2) {
                    modeButton("Later AI", icon: "sparkles", guided: false)
                    modeButton("Guided", icon: "doc.text", guided: true)
                }
                .padding(3)
                .background(Color(hex: "1B1B1E"), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.12)))
                Spacer(minLength: 8)
                if !messages.isEmpty {
                    Button("Clear") { conversation.reset(); inputText = "" }
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "A1A1AA"))
                }
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Close Later AI")
            }
            Text(conversation.manual ? "Step-by-step structured capture" : "Your personal vault assistant")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "A1A1AA"))
        }
        .buttonStyle(.plain)
    }

    private func modeButton(_ title: String, icon: String, guided: Bool) -> some View {
        let selected = conversation.manual == guided
        return Button {
            isInputFocused = false
            if guided {
                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    conversation.draft.content = inputText
                }
                conversation.continueManually()
            } else {
                conversation.manual = false
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(selected ? Color.black : Color.white.opacity(0.7))
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(selected ? LaterAIStyle.accent : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(guided ? "laterai.mode.guided" : "laterai.mode.ai")
    }

    // MARK: - Message List
    private var messageListView: some View {
        VStack(spacing: 18) {
            ForEach(messages) { msg in
                LaterAIChatRow(text: msg.text, isUser: msg.isUser, timestamp: msg.timestamp)
            }
        }
    }

    private var thinkingIndicatorView: some View {
        LaterAIThinkingIndicator(thinking: isThinking, statusText: "Later AI is writing...")
    }

    // MARK: - Search Matched Results View
    private var matchedResultsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATCHED ITEMS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.white.opacity(0.6))
                .tracking(0.5)

            ForEach(conversation.results) { item in
                Button { editingItem = item } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.parsedContentType.systemIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(LaterAIStyle.accent)
                            .frame(width: 32, height: 32)
                            .background(Color(white: 24.0/255), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            if let domain = item.domain {
                                Text(domain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                    .padding(12)
                    .background(Color(white: 20.0/255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Error View
    private func errorRetryView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.orange)
            HStack(spacing: 10) {
                Button("Retry") {
                    conversation.retry(items: allItems, context: modelContext)
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(LaterAIStyle.accent, in: Capsule())
                .foregroundColor(.black)

                Button("Continue manually") {
                    conversation.continueManually()
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(white: 24.0/255), in: Capsule())
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(white: 18.0/255), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Active Options Popups
    private var activeOptions: [LaterAIOptionItem] {
        guard !conversation.manual && !isThinking else { return [] }

        if conversation.needsClarification {
            return [
                LaterAIOptionItem(
                    title: "Save to Vault",
                    subtitle: "Store with AI tags",
                    icon: "tray.and.arrow.down.fill",
                    isPrimary: true
                ) {
                    sendOptionReply("Save to vault") {
                        conversation.save(context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "Just Chatting",
                    subtitle: "Don't save item",
                    icon: "bubble.left.and.bubble.right.fill",
                    isPrimary: false
                ) {
                    sendOptionReply("Just chatting") {
                        conversation.needsClarification = false
                        conversation.messages.append(LaterAIMessage(text: "Sounds good! What else would you like to know or find?", isUser: false))
                    }
                }
            ]
        }

        if conversation.needsReturnDate {
            return [
                LaterAIOptionItem(
                    title: "In 10 Minutes",
                    subtitle: "Quick return",
                    icon: "timer",
                    isPrimary: true
                ) {
                    let tenMin = Date().addingTimeInterval(600)
                    sendOptionReply("In 10 minutes") {
                        conversation.schedule(tenMin, intervalDescription: "(in 10 minutes)", context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "In 1 Hour",
                    subtitle: "Later today",
                    icon: "clock.arrow.circlepath",
                    isPrimary: false
                ) {
                    let oneHour = Date().addingTimeInterval(3600)
                    sendOptionReply("In 1 hour") {
                        conversation.schedule(oneHour, intervalDescription: "(in 1 hour)", context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "Tomorrow",
                    subtitle: "9:00 AM",
                    icon: "calendar.badge.clock",
                    isPrimary: false
                ) {
                    sendOptionReply("Tomorrow") {
                        conversation.schedule(Calendar.current.date(byAdding: .day, value: 1, to: Date()), context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "This Weekend",
                    subtitle: "Saturday morning",
                    icon: "sun.max.fill",
                    isPrimary: false
                ) {
                    sendOptionReply("This weekend") {
                        conversation.schedule(CaptureDraft.weekend(), context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "Next Week",
                    subtitle: "7 days from now",
                    icon: "calendar",
                    isPrimary: false
                ) {
                    sendOptionReply("Next week") {
                        conversation.schedule(Calendar.current.date(byAdding: .day, value: 7, to: Date()), context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "No Reminder",
                    subtitle: "Inbox only",
                    icon: "tray",
                    isPrimary: false
                ) {
                    sendOptionReply("No reminder") {
                        conversation.schedule(nil, context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "Choose Date",
                    subtitle: "Pick date & time",
                    icon: "slider.horizontal.3",
                    isPrimary: false
                ) {
                    chooseReturnDate = true
                }
            ]
        }

        if let saved = conversation.savedItem {
            return [
                LaterAIOptionItem(
                    title: "Schedule Return",
                    subtitle: "Set reminder date",
                    icon: "calendar.badge.clock",
                    isPrimary: true
                ) {
                    sendOptionReply("Schedule return") {
                        conversation.needsReturnDate = true
                        conversation.messages.append(LaterAIMessage(text: "When would you like to see it again?", isUser: false))
                    }
                },
                LaterAIOptionItem(
                    title: "Edit Details",
                    subtitle: "View title & tags",
                    icon: "pencil",
                    isPrimary: false
                ) {
                    editingItem = saved
                },
                LaterAIOptionItem(
                    title: "Undo Save",
                    subtitle: "Remove from vault",
                    icon: "arrow.uturn.backward",
                    isPrimary: false
                ) {
                    sendOptionReply("Undo save") {
                        conversation.undo(context: modelContext)
                    }
                },
                LaterAIOptionItem(
                    title: "Save Another",
                    subtitle: "Capture new item",
                    icon: "plus.circle.fill",
                    isPrimary: false
                ) {
                    sendOptionReply("Save another item") {
                        conversation.reset()
                    }
                }
            ]
        }

        return []
    }

    private var optionsTitle: String? {
        if conversation.needsClarification {
            return "Choose an action"
        } else if conversation.needsReturnDate {
            return "When would you like to return?"
        } else if conversation.savedItem != nil {
            return "Saved item options"
        }
        return nil
    }

    private func sendOptionReply(_ title: String, action: @escaping () -> Void) {
        LBHaptic.medium()
        withAnimation(.easeInOut(duration: 0.22)) {
            conversation.messages.append(LaterAIMessage(text: title, isUser: true))
        }
        action()
    }

    // MARK: - Attached Subject Bar
    @ViewBuilder
    private var attachedSubjectBar: some View {
        if let subject = LaterAIManager.shared.attachedSubject, conversation.savedItem == nil {
            HStack(spacing: 8) {
                Image(systemName: CaptureDraft.detectURL(subject) != nil ? "link.circle.fill" : "doc.text.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(LaterAIStyle.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ATTACHED ITEM TO SAVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(LaterAIStyle.accent)
                        .tracking(0.5)

                    Text(subject)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        LaterAIManager.shared.attachedSubject = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(white: 22.0/255), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Bottom ChatGPT Mobile Chat Input Bar
    private var bottomChatInputBar: some View {
        VStack(spacing: 8) {
            attachedSubjectBar
            if messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(promptSuggestions, id: \.self) { prompt in
                            Button { sendMessage(prompt) } label: {
                                HStack(spacing: 6) {
                                    Text(prompt).foregroundStyle(.white.opacity(0.85))
                                    Image(systemName: "arrow.right").foregroundStyle(LaterAIStyle.accent)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(hex: "1C1C1E"), in: Capsule())
                                .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                TextField("", text: $inputText,
                          prompt: Text("Message Later AI…").foregroundStyle(.white.opacity(0.4)), axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(LaterAIStyle.accent)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.vertical, 6)
                Button { sendMessage(inputText) } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(canSend ? Color.black : Color.white.opacity(0.35))
                        .frame(width: 36, height: 36)
                        .background(canSend ? LaterAIStyle.accent : .white.opacity(0.1), in: Circle())
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.leading, 16)
            .padding(6)
            .background(Color(hex: "1C1C1E"), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.12)))
            .buttonStyle(.plain)
        }
    }

    private var canSend: Bool {
        !isThinking && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func triggerInitialPrompt(_ prompt: String) {
        LaterAIManager.shared.initialPrompt = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sendMessage(prompt)
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        conversation.send(trimmed, items: allItems, context: modelContext)
        inputText = ""
    }

    private func dismiss() {
        isInputFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
            progress = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            isPresented = false
        }
    }
}
