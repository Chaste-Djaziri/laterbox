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

    @StateObject private var conversation = LaterAIConversation()

    public init(isPresented: Binding<Bool>, progress: Binding<CGFloat>) {
        self._isPresented = isPresented
        self._progress = progress
    }

    public var body: some View {
        let clampedProgress = max(0.0, min(1.0, progress))
        let travelFactor = (1.0 - clampedProgress)

        VStack(spacing: 12) {
            topBar

            GuidedCaptureView(draft: $conversation.draft, fillsAvailableSpace: true) {
                conversation.save(context: modelContext)
                dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0C0C0D").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .whiteStatusBar()
        .offset(y: travelFactor * -160)
        .opacity(clampedProgress)
        .onAppear {
            conversation.manual = true
            if let prompt = LaterAIManager.shared.initialPrompt {
                conversation.draft.content = prompt
            } else if let subject = LaterAIManager.shared.attachedSubject, !subject.isEmpty {
                conversation.draft.content = subject
            }
        }
        .onDisappear {
            StatusBarStyleModifier.apply(.light)
            conversation.reset()
            LaterAIManager.shared.attachedSubject = nil
            LaterAIManager.shared.initialPrompt = nil
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
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LaterAIStyle.accent)
                    Text("Guided Capture")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("laterai.mode.guided")

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Close Later AI")
            }
            Text("Step-by-step structured capture")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "A1A1AA"))
        }
        .buttonStyle(.plain)
    }

    private func dismiss() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
            progress = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            isPresented = false
            conversation.reset()
            LaterAIManager.shared.attachedSubject = nil
            LaterAIManager.shared.initialPrompt = nil
        }
    }
}
