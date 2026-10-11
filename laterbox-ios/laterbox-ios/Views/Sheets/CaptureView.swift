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
    @State private var savedItem: LBItem?
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
                    .accessibilityLabel("Close Capture")
                    .accessibilityIdentifier("Close Later AI")

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

                if let item = savedItem {
                    // Saved Success View with Undo and Done
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundColor(LaterAIStyle.accent)

                        VStack(spacing: 6) {
                            Text("Saved to Vault")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("‘\(item.title)’")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }

                        HStack(spacing: 16) {
                            Button {
                                item.status = "deleted"
                                item.updatedAt = Date()
                                item.isSyncPending = true
                                do {
                                    try modelContext.save()
                                    savedItem = nil
                                    draft = CaptureDraft()
                                    Task { await SyncCoordinator.shared.syncPendingItems(context: modelContext) }
                                } catch {
                                    item.status = "inbox"
                                    saveError = error.localizedDescription
                                }
                                LBHaptic.medium()
                            } label: {
                                Text("Undo")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color(white: 26.0 / 255), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                dismiss()
                                LBHaptic.light()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 12)
                                    .background(LaterAIStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Main Guided Content
                    GuidedCaptureView(draft: $draft, fillsAvailableSpace: true) {
                        do {
                            savedItem = try SyncCoordinator.shared.saveDraft(draft, context: modelContext)
                            LBHaptic.success()
                        } catch {
                            saveError = error.localizedDescription
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
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
