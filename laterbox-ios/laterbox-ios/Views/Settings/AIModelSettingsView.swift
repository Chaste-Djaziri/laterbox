import SwiftUI

struct AIModelSettingsView: View {
    @ObservedObject private var modelManager = LaterAIModelManager.shared

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Intelligence Engine", systemImage: "sparkles")
                            .font(.title2.bold())
                        Text("On-device intelligence and offline response assistant for capture and search.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // MARK: - On-Device Hardware Support Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            HStack(spacing: 12) {
                                Image(systemName: "cpu.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                    .frame(width: 42, height: 42)
                                    .background(AppTheme.accent, in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("On-Device Model")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(modelManager.deviceHardwareSummary)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            Spacer()

                            // Status Pill
                            HStack(spacing: 5) {
                                Image(systemName: modelManager.isOnDeviceModelSupported ? "checkmark.circle.fill" : "xmark.circle")
                                    .font(.system(size: 12, weight: .bold))
                                Text(modelManager.isOnDeviceModelSupported ? "Supported" : "Not Supported")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(modelManager.isOnDeviceModelSupported ? Color.green.opacity(0.15) : Color.black.opacity(0.06))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        modelManager.isOnDeviceModelSupported ? Color.green.opacity(0.3) : Color.black.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundColor(modelManager.isOnDeviceModelSupported ? Color(red: 22/255, green: 130/255, blue: 60/255) : AppTheme.textSecondary)
                        }

                        Text(modelManager.supportStatusMessage)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .background(Color.black.opacity(0.08))

                        if modelManager.isOnDeviceModelSupported {
                            Toggle(isOn: $modelManager.isOnDeviceModelEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable On-Device Model")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("Use hardware Neural Engine for private, zero-cloud processing")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .tint(Color.black)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("On-Device Model")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("Requires iPhone 15 Pro, iPhone 16, iPhone 17 or later with 8GB+ RAM")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                Spacer()
                                Text("Unavailable")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - Engine Selector Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Engine")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        if modelManager.isOnDeviceModelSupported && modelManager.isOnDeviceModelEnabled {
                            engineOptionRow(
                                title: "On-Device Neural Engine",
                                subtitle: "Apple Intelligence hardware · Zero data leaves device",
                                icon: "cpu",
                                isSelected: modelManager.selectedProvider == .onDevice,
                                action: { modelManager.selectedProvider = .onDevice }
                            )
                        }

                        engineOptionRow(
                            title: "Local responses",
                            subtitle: "Deterministic offline rules · 100% private",
                            icon: "wand.and.stars",
                            isSelected: modelManager.selectedProvider == .local,
                            action: { modelManager.selectedProvider = .local }
                        )
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - Search Refinement
                    Toggle(isOn: $modelManager.enableSearchRefine) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Search refinement")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Enhance queries locally for higher precision results")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .tint(Color.black)
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - Future Providers
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Cloud & Custom AI Providers", systemImage: "clock.badge")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Custom API keys (OpenAI, Anthropic, Ollama) and cloud providers will connect here once on-device foundation model pipelines are finalized.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Later AI Models")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func engineOptionRow(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 38, height: 38)
                    .background(isSelected ? AppTheme.accent : Color.black.opacity(0.05), in: Circle())
                    .foregroundColor(.black)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if isSelected {
                    Text("Active")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(AppTheme.accent, in: Capsule())
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.black.opacity(0.3))
                }
            }
            .padding(12)
            .background(isSelected ? Color.black.opacity(0.03) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
