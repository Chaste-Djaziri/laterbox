import SwiftUI

public struct ShortcutsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingQuickCaptureTest = false
    @State private var testSuccessMessage: String? = nil

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                            LBHaptic.light()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.04), in: Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Control Center & Quick Save")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Color.clear.frame(width: 38, height: 38)
                    }
                    .padding(.top, 4)

                    // Hero Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.accent)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "plus.square.fill.on.square.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Control Center Capture")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Instant access from tools top")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Text("Add the LaterBox Quick Save control directly to your iOS Control Center. Capture thoughts, notes, and links fast with nothing attached without opening the app.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 18)

                    // Setup Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HOW TO ADD TO CONTROL CENTER")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        instructionStep(
                            number: "1",
                            title: "Open Control Center",
                            description: "Swipe down from the top-right corner of your screen (tools top)."
                        )

                        Divider().opacity(0.12)

                        instructionStep(
                            number: "2",
                            title: "Enter Edit Mode",
                            description: "Tap the ‘+’ at the top left or touch and hold on empty space."
                        )

                        Divider().opacity(0.12)

                        instructionStep(
                            number: "3",
                            title: "Tap ‘Add a Control’",
                            description: "Tap the Add a Control button at the bottom of the screen."
                        )

                        Divider().opacity(0.12)

                        instructionStep(
                            number: "4",
                            title: "Select LaterBox Quick Save",
                            description: "Scroll or search for LaterBox and tap Quick Save to place it in your Control Center."
                        )
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 18)

                    // Safari Toolbar & Share Sheet Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "safari")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.accent)
                            Text("Safari Toolbar & Blank Sharing")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Text("You can also tap LaterBox from Safari's tools menu or Share Sheet anytime. Even with nothing attached or selected, LaterBox opens the clean Quick Save composer to add what you need.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 18)

                    // Action Button section
                    Button(action: {
                        LBHaptic.medium()
                        showingQuickCaptureTest = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Test Quick Save Composer")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showingQuickCaptureTest) {
            QuickCaptureSheet()
        }
    }

    private func instructionStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}
