//
//  CaptureView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData

public struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var draft = CaptureDraft()
    @State private var saveError: String?

    public init() {}

    public var body: some View {
        ZStack {
            // Dark elegant background matching guided capture style
            Color(hex: "0C0C0D")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button {
                        dismiss()
                        LBHaptic.light()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Inbox")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(LaterAIStyle.accent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Capture")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Balance layout width
                    Color.clear
                        .frame(width: 60, height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Main Guided Content
                GuidedCaptureView(draft: $draft, fillsAvailableSpace: true) {
                    do {
                        _ = try SyncCoordinator.shared.saveDraft(draft, context: modelContext)
                        LBHaptic.success()
                        dismiss()
                    } catch {
                        saveError = error.localizedDescription
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .alert("Error Saving Capture", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let saveError {
                Text(saveError)
            }
        }
    }
}
