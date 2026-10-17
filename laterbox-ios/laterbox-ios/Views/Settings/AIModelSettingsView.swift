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
                        Text("LaterBox currently uses an offline response assistant for capture and search.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: modelManager.selectedProvider.iconName)
                            .frame(width: 42, height: 42)
                            .background(AppTheme.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Local responses").font(.headline)
                            Text("Available now · works offline").font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("Active").font(.caption.bold()).padding(.horizontal, 9).padding(.vertical, 5)
                            .background(AppTheme.accent, in: Capsule())
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 10) {
                        Label("AI providers", systemImage: "clock.badge")
                            .font(.headline)
                        Text("Cloud and custom AI providers are coming soon. Provider switching and API-key connections are disabled until they are implemented.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))

                    Toggle("Search refinement", isOn: $modelManager.enableSearchRefine)
                        .padding(16)
                        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(20)
            }
        }
        .navigationTitle("Later AI Models")
        .navigationBarTitleDisplayMode(.inline)
    }
}
