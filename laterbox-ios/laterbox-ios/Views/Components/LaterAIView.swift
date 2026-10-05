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

        ZStack {
            // Feather-Flow Black Background Drape with Feathered Fading Bottom (No Hard Line)
            FeatherFadingBackdrop(progress: progress)

            VStack(spacing: 0) {
                // Top Grab Handle & Header (Rides down from top)
                topBar
                    .offset(y: travelFactor * -60)

                // Chat Messages / Welcome Empty State (Rides down with center drape)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if conversation.manual {
                                GuidedCaptureView(draft: $conversation.draft) { conversation.save(context: modelContext) }
                                if let reason = AppleLaterAIProvider.unavailableReason { Text(reason).font(.caption).foregroundStyle(.secondary) }
                            } else if messages.isEmpty {
                                if conversation.savedItem == nil { emptyStateView }
                            } else {
                                messageListView
                            }

                            conversationActions

                            if isThinking {
                                thinkingIndicatorView
                            }

                            Color.clear
                                .frame(height: 12)
                                .id("bottomAnchor")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
                .offset(y: travelFactor * -120)

                // Bottom ChatGPT Mobile-Style Chat Input Dock (Cascades down to dock)
                if !conversation.manual && conversation.chatAvailable {
                    bottomChatInputBar.offset(y: travelFactor * -80)
                }
            }
            .offset(y: travelFactor * -160)
            .opacity(max(0.0, min(1.0, (clampedProgress - 0.08) / 0.74)))
            .mask(
                FeatherFlowShape(progress: progress, centerDipFraction: 0.32)
                    .ignoresSafeArea()
            )
        }
        .onDisappear { conversation.reset() }
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
            withAnimation { conversation.reset() }
        })
    }

    // MARK: - Empty State (ChatGPT Mobile Style)
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

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

            Spacer(minLength: 30)
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
        LaterAIThinkingIndicator(thinking: isThinking)
    }

    // MARK: - Bottom ChatGPT Mobile Chat Input Bar
    private var bottomChatInputBar: some View {
        LaterAIComposer(text: $inputText, thinking: isThinking,
                        attach: { conversation.continueManually() },
                        send: { sendMessage(inputText) })
    }

    // MARK: - Actions
    private var inboxItemsCount: Int {
        allItems.filter { $0.status == "inbox" }.count
    }

    private var returnItemsCount: Int {
        allItems.filter { $0.returnAt != nil }.count
    }

    private func sendMessage(_ text: String) {
        conversation.send(text, items: allItems, context: modelContext)
        inputText = ""
    }

    private var conversationActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let error = conversation.error {
                Text(error).foregroundStyle(.orange)
                HStack {
                    Button("Retry") { conversation.retry(items: allItems, context: modelContext) }
                    Button("Continue manually") { conversation.continueManually() }
                }
            }
            if conversation.needsClarification {
                HStack {
                    Button("Save this") { conversation.save(context: modelContext) }
                    Button("Just chatting") { conversation.needsClarification = false }
                }
            }
            ForEach(conversation.results) { item in
                Button { editingItem = item } label: {
                    HStack { Image(systemName: item.parsedContentType.systemIcon); Text(item.title); Spacer(); Image(systemName: "chevron.right") }
                }
            }
            if let item = conversation.savedItem {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title).font(.headline)
                    Text(item.tags.map { "#" + $0 }.joined(separator: " ")).font(.caption)
                    HStack {
                        Button("Edit") { editingItem = item }
                        Button("Undo") { conversation.undo(context: modelContext) }
                        Button("Save another") { conversation.reset() }
                    }
                }
            }
            if conversation.needsReturnDate {
                Text("When would you like to see it again?")
                ViewThatFits {
                    HStack { returnButtons }
                    VStack(alignment: .leading) { returnButtons }
                }
                if chooseReturnDate {
                    CaptureDateChoices(date: $selectedReturnDate)
                    Button("Set date") { conversation.schedule(selectedReturnDate, context: modelContext); chooseReturnDate = false }
                }
            }
        }
        .buttonStyle(CaptureChoiceStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $editingItem) { item in NavigationStack { ItemDetailView(item: item) } }
    }

    @ViewBuilder private var returnButtons: some View {
        Button("Tomorrow") { conversation.schedule(Calendar.current.date(byAdding: .day, value: 1, to: Date()), context: modelContext) }
        Button("This weekend") { conversation.schedule(CaptureDraft.weekend(), context: modelContext) }
        Button("Choose date") { chooseReturnDate = true }
        Button("No reminder") { conversation.schedule(nil, context: modelContext) }
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
