import SwiftUI

/// Practical, device-guided tutorials for getting started with LaterBox.
public struct LearnLaterBoxView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("laterbox.learn.homeQuickSave.imageGuide.step.v2") private var currentStep = 0
    @AppStorage("laterbox.learn.homeQuickSave.imageGuide.complete.v2") private var completed = false
    @State private var cannotOpenShortcuts = false

    private struct GuideStep {
        let title: String
        let detail: String
        let icon: String
        let arrowStart: CGPoint
        let arrowTip: CGPoint
        var secondaryHighlights: [CGPoint] = []
    }

    // One screen for each of the nine original, user-supplied Shortcuts screenshots.
    // Hotspot positions are normalized to the 1320 × 2868 originals.
    private let steps: [GuideStep] = [
        GuideStep(
            title: "Create a shortcut",
            detail: "Open Apple's Shortcuts app. On the Shortcuts screen, tap the plus (+) button in the bottom center to start a new shortcut.",
            icon: "plus.circle.fill",
            arrowStart: CGPoint(x: 0.75, y: 0.75),
            arrowTip: CGPoint(x: 0.50, y: 0.94)
        ),
        GuideStep(
            title: "Find LaterBox in the actions",
            detail: "In the new shortcut editor, browse or scroll the available apps in the action picker. Find LaterBox. You can also use Search Actions to locate it.",
            icon: "list.bullet",
            arrowStart: CGPoint(x: 0.75, y: 0.55),
            arrowTip: CGPoint(x: 0.48, y: 0.78)
        ),
        GuideStep(
            title: "Choose LaterBox",
            detail: "Tap LaterBox in the app list to see the actions it offers to Apple Shortcuts.",
            icon: "cube.box",
            arrowStart: CGPoint(x: 0.76, y: 0.54),
            arrowTip: CGPoint(x: 0.44, y: 0.39)
        ),
        GuideStep(
            title: "Select Quick Save to LaterBox",
            detail: "Tap Quick Save to LaterBox. Do NOT choose Open LaterBox Quick Save: that other action opens the app instead of saving directly from Shortcuts.",
            icon: "checkmark.circle.fill",
            arrowStart: CGPoint(x: 0.77, y: 0.40),
            arrowTip: CGPoint(x: 0.48, y: 0.22)
        ),
        GuideStep(
            title: "Open shortcut details",
            detail: "Once the action has been added, tap the small ⓘ information icon at the bottom center of the shortcut editor. It opens the shortcut Details panel.",
            icon: "info.circle.fill",
            arrowStart: CGPoint(x: 0.76, y: 0.74),
            arrowTip: CGPoint(x: 0.50, y: 0.955)
        ),
        GuideStep(
            title: "Add it to your Home Screen",
            detail: "In the shortcut Details panel, tap Add to Home Screen. This creates an icon for the shortcut, not a second copy of the LaterBox app.",
            icon: "house",
            arrowStart: CGPoint(x: 0.75, y: 0.67),
            arrowTip: CGPoint(x: 0.52, y: 0.48)
        ),
        GuideStep(
            title: "Personalize the shortcut icon",
            detail: "Choose an icon design and color, and edit the Home Screen name to something easy to recognize, like Quick Save. Review the preview, then tap Done in the top-right corner.",
            icon: "paintpalette.fill",
            arrowStart: CGPoint(x: 0.57, y: 0.28),
            arrowTip: CGPoint(x: 0.91, y: 0.08),
            secondaryHighlights: [CGPoint(x: 0.43, y: 0.55), CGPoint(x: 0.46, y: 0.73)]
        ),
        GuideStep(
            title: "Use it from your Home Screen",
            detail: "Return to the Home Screen, locate the new LaterBox Quick Save icon, and tap it. You won't need to open LaterBox first.",
            icon: "house.fill",
            arrowStart: CGPoint(x: 0.69, y: 0.44),
            arrowTip: CGPoint(x: 0.19, y: 0.24)
        ),
        GuideStep(
            title: "Type your note or link and save",
            detail: "The shortcut asks for a Note or URL. Type the content you want to save; Title and When to Return are optional. Tap Done to finish and save it to LaterBox.",
            icon: "square.and.pencil",
            arrowStart: CGPoint(x: 0.52, y: 0.55),
            arrowTip: CGPoint(x: 0.81, y: 0.38),
            secondaryHighlights: [CGPoint(x: 0.44, y: 0.26)]
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

                        ShortcutGuideScreenshotView(
                            stepNumber: safeStep + 1,
                            arrowStart: steps[safeStep].arrowStart,
                            arrowTip: steps[safeStep].arrowTip,
                            secondaryHighlights: steps[safeStep].secondaryHighlights
                        )

                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap")
                            Text("Follow the red arrow. Tap the screenshot to enlarge.")
                        }
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                        if safeStep == 3 {
                            actionComparison
                        }

                        if safeStep <= 6 {
                            shortcutButton("Open Shortcuts", systemImage: "arrow.up.right.square", create: false)
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
            .id(safeStep)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            navigationControls
        }
        .navigationTitle("Learn LaterBox")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't open Shortcuts", isPresented: $cannotOpenShortcuts) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open Apple's Shortcuts app from your Home Screen, then follow this guide.")
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            if safeStep > 0 {
                Button {
                    LBHaptic.light()
                    currentStep = safeStep - 1
                    completed = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
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
                    Text(safeStep == steps.count - 1 ? (completed ? "Guide complete" : "Finish guide") : "Next step")
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var safeStep: Int { min(max(currentStep, 0), steps.count - 1) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Make LaterBox yours")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("A visual walkthrough to create and use a Home Screen shortcut for saving without launching the app.")
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
