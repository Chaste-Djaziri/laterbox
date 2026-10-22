import SwiftUI

/// Practical, device-guided tutorials for getting started with LaterBox.
public struct LearnLaterBoxView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("laterbox.learn.homeQuickSave.step") private var currentStep = 0
    @AppStorage("laterbox.learn.homeQuickSave.complete") private var completed = false
    @State private var cannotOpenShortcuts = false

    private struct GuideStep {
        let title: String
        let detail: String
        let icon: String
    }

    private let steps: [GuideStep] = [
        GuideStep(
            title: "Find LaterBox in Shortcuts",
            detail: "Open Shortcuts and search for LaterBox. Choose Quick Save to LaterBox. If you see its blue Add button, tap it to add the shortcut. If not, choose Start a new shortcut below.",
            icon: "magnifyingglass"
        ),
        GuideStep(
            title: "Add the right action",
            detail: "If you started with a blank shortcut, tap Add Action (or Search Actions), search for LaterBox, and choose Quick Save to LaterBox. If you already tapped Add for the correct shortcut, move to the next step.",
            icon: "plus.square.on.square"
        ),
        GuideStep(
            title: "Keep it ready for anything",
            detail: "Leave Note or URL unfilled so the shortcut asks what to save each time. Title and When to Return are optional. You can rename the shortcut Quick Save, then tap Done.",
            icon: "slider.horizontal.3"
        ),
        GuideStep(
            title: "Put it on your Home Screen",
            detail: "Open your saved Quick Save shortcut for editing. Open Details (the ⓘ or details menu), choose Add to Home Screen, customize the name or icon if you like, then tap Add.",
            icon: "house"
        ),
        GuideStep(
            title: "Try your new shortcut",
            detail: "Tap Quick Save on your Home Screen. Enter a note or link when asked, optionally provide a title or return time, then confirm. It saves without first opening the LaterBox app.",
            icon: "checkmark.circle"
        )
    ]

    public init() {}

    public var body: some View {
        ZStack {
            AppTheme.canvasBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Home Screen Quick Save")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Save notes and links without opening the app")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        Text("This guide uses **Quick Save to LaterBox**, not **Open LaterBox Quick Save**. The first saves directly through Shortcuts; the second launches the in-app composer.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityIdentifier("learn.homeQuickSave.intro")

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("STEP \(min(max(currentStep, 0), steps.count - 1) + 1) OF \(steps.count)")
                                .font(.caption.weight(.bold))
                                .tracking(0.8)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            if completed {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: "47723C"))
                            }
                        }

                        HStack(spacing: 5) {
                            ForEach(steps.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index <= safeStep ? AppTheme.textPrimary : Color.black.opacity(0.09))
                                    .frame(height: 5)
                            }
                        }
                        .accessibilityLabel("Step \(safeStep + 1) of \(steps.count)")

                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: steps[safeStep].icon)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 46, height: 46)
                                .background(AppTheme.accent.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))

                            VStack(alignment: .leading, spacing: 8) {
                                Text(steps[safeStep].title)
                                    .font(.system(size: 19, weight: .bold))
                                Text(steps[safeStep].detail)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if safeStep == 0 || safeStep == 1 {
                            actionComparison
                        }
                        if safeStep == 2 {
                            Label("No need to add the separate Open App action or Ask for Input action.", systemImage: "lightbulb")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        if safeStep == 0 {
                            shortcutButton("Open Shortcuts", systemImage: "arrow.up.right.square", create: false)
                            shortcutButton("Start a new shortcut", systemImage: "plus.circle", create: true)
                        } else if safeStep == 1 {
                            shortcutButton("Create in Shortcuts", systemImage: "plus.circle.fill", create: true)
                        } else if safeStep == 3 {
                            shortcutButton("Open Shortcuts", systemImage: "arrow.up.right.square", create: false)
                        }

                        HStack(spacing: 12) {
                            if safeStep > 0 {
                                Button {
                                    LBHaptic.light()
                                    currentStep = safeStep - 1
                                } label: {
                                    Text("Back")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 13))
                                }
                                .foregroundStyle(AppTheme.textPrimary)
                                .buttonStyle(.plain)
                            }
                            Button {
                                LBHaptic.light()
                                if safeStep == steps.count - 1 {
                                    completed = true
                                } else {
                                    currentStep = safeStep + 1
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text(safeStep == steps.count - 1 ? (completed ? "All set" : "Finish guide") : "Next step")
                                    Image(systemName: safeStep == steps.count - 1 ? "checkmark" : "arrow.right")
                                }
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .buttonStyle(.plain)
                            .disabled(safeStep == steps.count - 1 && completed)
                        }
                    }
                    .padding(18)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityIdentifier("learn.homeQuickSave.steps")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Other ways to save")
                            .font(.system(size: 16, weight: .bold))
                        NavigationLink {
                            ShortcutsSettingsView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.grid.2x2")
                                    .frame(width: 27)
                                Text("Control Center and Share Sheet")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18))

                    Link(destination: URL(string: "https://support.apple.com/guide/shortcuts/apd735880972/ios")!) {
                        Label("Apple's official Home Screen shortcut guide", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Learn LaterBox")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't open Shortcuts", isPresented: $cannotOpenShortcuts) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open Apple's Shortcuts app from your Home Screen, then follow this guide.")
        }
    }

    private var safeStep: Int { min(max(currentStep, 0), steps.count - 1) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Make LaterBox yours")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("A guided setup for the fastest ways to save. Start with a one-tap Home Screen shortcut.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    private var actionComparison: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "47723C"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Save to LaterBox")
                        .font(.subheadline.weight(.semibold))
                    Text("Choose this • saves from the Shortcuts prompt")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(AppTheme.accent.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open LaterBox Quick Save")
                        .font(.subheadline.weight(.semibold))
                    Text("Not this one • opens the LaterBox app")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func shortcutButton(_ title: String, systemImage: String, create: Bool) -> some View {
        Button {
            let path = create ? "shortcuts://create-shortcut" : "shortcuts://"
            guard let url = URL(string: path) else { cannotOpenShortcuts = true; return }
            openURL(url) { success in
                if !success { cannotOpenShortcuts = true }
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(.white)
                .background(AppTheme.darkSurface, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}
