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
    @State private var messages: [LaterAIMessage] = []
    @State private var isThinking: Bool = false
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
        ZStack {
            // Feather-Flow Black Background Drape with Feathered Fading Bottom (No Hard Line)
            FeatherFadingBackdrop(progress: progress)

            VStack(spacing: 0) {
                // Top Grab Handle & Header
                topBar

                // Chat Messages / Welcome Empty State
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            if messages.isEmpty {
                                emptyStateView
                            } else {
                                messageListView
                            }

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

                // Bottom ChatGPT Mobile-Style Chat Input Dock
                bottomChatInputBar
            }
            .opacity(max(0.0, min(1.0, (progress - 0.28) / 0.62)))
            .offset(y: (1.0 - max(0.0, min(1.0, progress))) * -35)
            .ignoresSafeArea(edges: .top)
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
        VStack(spacing: 8) {
            // Top pull handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 38, height: 4.5)
                .padding(.top, 8)

            HStack {
                // Dismiss / Dropdown close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }

                Spacer()

                // "Later AI" Title with Brand Accent
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.accent)

                    Text("Later AI")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)

                    Text("PREVIEW")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppTheme.accent))
                }

                Spacer()

                // Clear / New Chat Button
                Button {
                    withAnimation {
                        messages.removeAll()
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(messages.isEmpty ? Color.white.opacity(0.3) : .white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .disabled(messages.isEmpty)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.08))
        }
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
                if msg.isUser {
                    HStack {
                        Spacer(minLength: 48)
                        Text(msg.text)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(hex: "272729"))
                            )
                    }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        // AI Avatar
                        Circle()
                            .fill(Color(hex: "1C1C1E"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(msg.text)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .lineSpacing(4)

                            Text(msg.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.35))
                        }

                        Spacer(minLength: 32)
                    }
                }
            }
        }
    }

    // MARK: - Thinking / Typing Indicator
    private var thinkingIndicatorView: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color(hex: "1C1C1E"))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                )

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(AppTheme.accent.opacity(0.8))
                        .frame(width: 7, height: 7)
                        .scaleEffect(isThinking ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: isThinking
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1A1A"))
            )

            Spacer()
        }
    }

    // MARK: - Bottom ChatGPT Mobile Chat Input Bar
    private var bottomChatInputBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                // Attach / Plus Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }

                // Chat Input Field
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Message Later AI...", text: $inputText, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .tint(AppTheme.accent)
                        .lineLimit(1...5)
                        .padding(.vertical, 8)
                        .padding(.leading, 4)

                    // Right Button: Waveform/Mic when empty, Arrow Send when text entered
                    let hasText = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    Button {
                        if hasText {
                            sendMessage(inputText)
                        } else {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    } label: {
                        if hasText {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white))
                        } else {
                            Image(systemName: "waveform")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.75))
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.bottom, 2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "1F1F21"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Legal Disclaimer
            Text("Later AI can make mistakes. Verify important info.")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.35))
                .padding(.bottom, 6)
        }
        .background(Color.black)
    }

    // MARK: - Actions
    private var inboxItemsCount: Int {
        allItems.filter { $0.status == "inbox" }.count
    }

    private var returnItemsCount: Int {
        allItems.filter { $0.returnAt != nil }.count
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let userMsg = LaterAIMessage(text: trimmed, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isThinking = true

        // Generate contextual Later AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isThinking = false
            let reply = generateResponse(for: trimmed)
            messages.append(LaterAIMessage(text: reply, isUser: false))
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func generateResponse(for prompt: String) -> String {
        let p = prompt.lowercased()

        if p.contains("inbox") || p.contains("summarize") {
            let count = inboxItemsCount
            if count == 0 {
                return "Your Inbox is completely clear! All saved items have been triaged or archived."
            } else {
                return "You have \(count) unsorted item\(count == 1 ? "" : "s") in your Inbox. Would you like to review them one by one, or assign return reminders?"
            }
        } else if p.contains("return") || p.contains("deadline") {
            let count = returnItemsCount
            if count == 0 {
                return "No items have active return deadlines scheduled right now. You can set return dates from any item's action menu."
            } else {
                return "You have \(count) item\(count == 1 ? "" : "s") scheduled in your Returns calendar. Make sure to check the Returns tab for items needing attention today."
            }
        } else if p.contains("clean") || p.contains("delete") || p.contains("old") {
            return "I can help identify duplicates or items saved over 30 days ago that remain unread. Head to Library > Recently Deleted or tap triage to clean up."
        } else {
            return "I've analyzed your LaterBox vault. You currently have \(allItems.count) total saved items across your collections. How else can I assist with your queue?"
        }
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
