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
    @State private var forceShowTextInput = false
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

        ZStack {
            // Feather-Flow Black Background Drape with Feathered Fading Bottom (No Hard Line)
            FeatherFadingBackdrop(progress: progress)

            VStack(spacing: 0) {
                // Top Grab Handle & Header (Rides down from top)
                topBar
                    .offset(y: travelFactor * -60)

                // Chat Messages / Welcome Empty State (Allows scrolling back up to all previous conversations)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if conversation.manual {
                                GuidedCaptureView(
                                    draft: $conversation.draft,
                                    onCancel: conversation.chatAvailable ? {
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            conversation.manual = false
                                        }
                                    } : nil
                                ) {
                                    conversation.save(context: modelContext)
                                }
                                if let reason = AppleLaterAIProvider.unavailableReason { Text(reason).font(.caption).foregroundStyle(.secondary) }
                            } else if messages.isEmpty && conversation.savedItem == nil {
                                emptyStateView
                            } else {
                                messageListView
                            }

                            if !conversation.results.isEmpty {
                                matchedResultsView
                            }

                            if let error = conversation.error {
                                errorRetryView(error)
                            }

                            if isThinking {
                                thinkingIndicatorView
                            }

                            Color.clear
                                .frame(height: 24)
                                .id("bottomAnchor")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.28)) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: isThinking) { _, thinking in
                        if thinking {
                            withAnimation(.easeOut(duration: 0.28)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                .offset(y: travelFactor * -120)

                // Bottom Area: Options Dock when popups are active, or standard Chat Composer
                if !conversation.manual && conversation.chatAvailable {
                    if !activeOptions.isEmpty && !forceShowTextInput {
                        LaterAIOptionsDock(
                            title: optionsTitle,
                            options: activeOptions,
                            onManualType: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    forceShowTextInput = true
                                }
                            }
                        )
                        .offset(y: travelFactor * -80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        VStack(spacing: 6) {
                            if !activeOptions.isEmpty && forceShowTextInput {
                                HStack {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            forceShowTextInput = false
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "square.grid.2x2")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Show quick options")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(LaterAIStyle.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(Color(white: 24.0/255), in: Capsule())
                                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                            }

                            bottomChatInputBar
                        }
                        .offset(y: travelFactor * -80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .offset(y: travelFactor * -160)
            .opacity(max(0.0, min(1.0, (clampedProgress - 0.08) / 0.74)))
            .mask(
                FeatherFlowShape(progress: progress, centerDipFraction: 0.32)
                    .ignoresSafeArea()
            )
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
                    .colorScheme(.dark)
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
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        // Dragging UP to dismiss smoothly
                        let delta = abs(value.translation.height) / 260.0
                        progress = max(0.0, 1.0 - delta)
                    }
                }
                .onEnded { value in
                    if value.translation.height < -60 || value.predictedEndTranslation.height < -120 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            progress = 1.0
                        }
                    }
                }
        )
    }

    // MARK: - Top Header Bar
    private var topBar: some View {
        LaterAIHeader(canReset: !messages.isEmpty, close: { dismiss() }, reset: {
            withAnimation {
                conversation.reset()
                forceShowTextInput = false
            }
        })
    }

    // MARK: - Empty State (ChatGPT Mobile Style)
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 30)

            // Glowing Brand Orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accent.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)

                Circle()
                    .fill(Color(hex: "1C1C1E"))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(AppTheme.accent)
            }

            // Headline
            VStack(spacing: 8) {
                Text("How can I help you today?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Ask about your saved items, upcoming return dates, or organize your vault.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Prompt Suggestion Chips
            VStack(spacing: 10) {
                ForEach(promptSuggestions, id: \.self) { prompt in
                    Button {
                        sendMessage(prompt)
                    } label: {
                        HStack {
                            Text(prompt)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.9))
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "171717"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 20)
        }
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
                    title: "Tomorrow",
                    subtitle: "9:00 AM",
                    icon: "calendar.badge.clock",
                    isPrimary: true
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
            forceShowTextInput = false
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
        VStack(spacing: 6) {
            attachedSubjectBar
            LaterAIComposer(text: $inputText, thinking: isThinking,
                            attach: { conversation.continueManually() },
                            send: { sendMessage(inputText) })
        }
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
        forceShowTextInput = false
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
