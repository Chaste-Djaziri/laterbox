//
//  AIModelSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI

struct AIModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @ObservedObject private var modelManager = LaterAIModelManager.shared

    @State private var showingKeyText = false
    @State private var testingConnection = false
    @State private var testResultMessage: String?
    @State private var testIsError = false
    @State private var showingCustomModelField = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    proBannerCard
                    activeSummaryCard
                    providerSelectionSection

                    if coordinator.isProUser && modelManager.selectedProvider.isCustomKey {
                        customKeyConfigurationSection
                    }

                    searchRefineSection
                    privacyFooterSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Later AI Models")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Text("Intelligence Engine")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text("Configure the AI models powering conversational chat, item classification, tag generation, and search refinement.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(.top, 4)
    }

    // MARK: - Pro Banner
    @ViewBuilder
    private var proBannerCard: some View {
        if !coordinator.isProUser {
            Button { coordinator.showingPlansSheet = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                    Text("Unlock model selection and search refinement with Pro")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(14)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active Summary Card
    private var activeSummaryCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 44, height: 44)
                Image(systemName: modelManager.selectedProvider.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(modelManager.selectedProvider.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    Text(modelManager.activeModelName)
                        .font(.caption.monospaced())
                        .foregroundColor(AppTheme.textSecondary)

                    if coordinator.isProUser && modelManager.enableSearchRefine {
                        Text("• Refine Active")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Color.green)
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Active")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppTheme.accent)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    // MARK: - Provider Selection Section
    private var providerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select AI Provider")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(AIProviderType.allCases) { provider in
                    providerRow(provider: provider)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }

    private func providerRow(provider: AIProviderType) -> some View {
        let selected = modelManager.selectedProvider == provider
        let locked = !coordinator.isProUser
        return Button {
            guard !locked else {
                coordinator.showingPlansSheet = true
                return
            }
            LBHaptic.light()
            modelManager.selectedProvider = provider
            testResultMessage = nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: provider.iconName)
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accent, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(provider.displayName).font(.subheadline.weight(.medium))
                    Text(provider.subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if locked {
                    Label("Pro", systemImage: "lock").font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(selected ? AppTheme.textPrimary : AppTheme.textTertiary)
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(12)
            .background(selected && !locked ? AppTheme.accent.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ai.provider.\(provider.rawValue)")
    }

    // MARK: - Custom Key Configuration Section
    private var customKeyConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(modelManager.selectedProvider.shortName) Credentials & Model")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 16) {
                apiKeyInputSection
                Divider().background(AppTheme.cardBorder)
                modelSelectionSection
                Divider().background(AppTheme.cardBorder)
                testConnectionSection
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }

    private var apiKeyInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("API Key")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button(action: {
                    if let paste = UIPasteboard.general.string {
                        LBHaptic.light()
                        switch modelManager.selectedProvider {
                        case .customGemini: modelManager.geminiApiKey = paste.trimmingCharacters(in: .whitespacesAndNewlines)
                        case .customOpenAI: modelManager.openAIApiKey = paste.trimmingCharacters(in: .whitespacesAndNewlines)
                        case .customClaude: modelManager.claudeApiKey = paste.trimmingCharacters(in: .whitespacesAndNewlines)
                        default: break
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                }
            }

            HStack {
                if showingKeyText {
                    TextField(keyPlaceholder, text: apiKeyBinding)
                        .font(.system(size: 14, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(keyPlaceholder, text: apiKeyBinding)
                        .font(.system(size: 14, design: .monospaced))
                }

                Button(action: { showingKeyText.toggle() }) {
                    Image(systemName: showingKeyText ? "eye.slash" : "eye")
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Model")
                .font(.caption.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availablePresetModels, id: \.self) { model in
                        modelChip(model: model)
                    }
                }
                .padding(.vertical, 2)
            }

            DisclosureGroup(isExpanded: $showingCustomModelField) {
                TextField("e.g. custom-fine-tuned-model", text: selectedModelBinding)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.top, 4)
            } label: {
                Text("Use Custom Model Name")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func modelChip(model: String) -> some View {
        let isSelected = selectedModelBinding.wrappedValue == model
        Button(action: {
            LBHaptic.light()
            selectedModelBinding.wrappedValue = model
            testResultMessage = nil
        }) {
            Text(model)
                .font(.caption.weight(isSelected ? .bold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.accent : Color.black.opacity(0.05))
                )
                .foregroundColor(AppTheme.textPrimary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? AppTheme.textPrimary.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var testConnectionSection: some View {
        VStack(spacing: 8) {
            Button(action: runConnectionTest) {
                HStack(spacing: 8) {
                    if testingConnection {
                        ProgressView()
                            .tint(AppTheme.textPrimary)
                    } else {
                        Image(systemName: "bolt.horizontal.circle.fill")
                    }
                    Text(testingConnection ? "Testing Connection..." : "Test Connection")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.accent)
                .foregroundColor(AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(testingConnection || apiKeyBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let result = testResultMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: testIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(testIsError ? Color.red : Color.green)
                        .font(.caption)
                    Text(result)
                        .font(.caption)
                        .foregroundColor(testIsError ? Color.red : AppTheme.textPrimary)
                        .lineLimit(3)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Search & Refine Section
    private var searchRefineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(
                get: { coordinator.isProUser && modelManager.enableSearchRefine },
                set: { enabled in
                    if coordinator.isProUser {
                        modelManager.enableSearchRefine = enabled
                    } else {
                        coordinator.showingPlansSheet = true
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Semantic Search").font(.subheadline.weight(.medium))
                        if !coordinator.isProUser {
                            Label("Pro", systemImage: "lock")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Text("Refine searches by topic, content type, and return date.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .tint(AppTheme.textPrimary)
            .accessibilityIdentifier("ai.searchRefine")
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(AppTheme.cardBorder))
    }

    // MARK: - Privacy Footer Section
    private var privacyFooterSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(AppTheme.textSecondary)
                .font(.caption)

            Text("Custom API keys are stored in this device's App Group sandbox and are never shared with or sent through LaterBox servers. All requests connect directly from your device to the respective provider.")
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    // MARK: - Helpers
    private var keyPlaceholder: String {
        switch modelManager.selectedProvider {
        case .customGemini: return "AIzaSy..."
        case .customOpenAI: return "sk-proj-..."
        case .customClaude: return "sk-ant-..."
        default: return "API Key"
        }
    }

    private var apiKeyBinding: Binding<String> {
        switch modelManager.selectedProvider {
        case .customGemini: return $modelManager.geminiApiKey
        case .customOpenAI: return $modelManager.openAIApiKey
        case .customClaude: return $modelManager.claudeApiKey
        default: return .constant("")
        }
    }

    private var availablePresetModels: [String] {
        switch modelManager.selectedProvider {
        case .customGemini: return AIModelPresets.geminiModels
        case .customOpenAI: return AIModelPresets.openAIModels
        case .customClaude: return AIModelPresets.claudeModels
        default: return []
        }
    }

    private var selectedModelBinding: Binding<String> {
        switch modelManager.selectedProvider {
        case .customGemini: return $modelManager.geminiModel
        case .customOpenAI: return $modelManager.openAIModel
        case .customClaude: return $modelManager.claudeModel
        default: return .constant("")
        }
    }

    private func runConnectionTest() {
        guard coordinator.isProUser else {
            LBHaptic.medium()
            coordinator.showingPlansSheet = true
            return
        }
        LBHaptic.medium()
        testingConnection = true
        testResultMessage = nil
        testIsError = false

        Task {
            do {
                let successMessage = try await modelManager.testConnection(for: modelManager.selectedProvider)
                await MainActor.run {
                    testingConnection = false
                    testIsError = false
                    testResultMessage = successMessage
                    LBHaptic.success()
                }
            } catch {
                await MainActor.run {
                    testingConnection = false
                    testIsError = true
                    testResultMessage = error.localizedDescription
                    LBHaptic.error()
                }
            }
        }
    }
}
