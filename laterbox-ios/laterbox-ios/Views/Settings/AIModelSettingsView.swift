//
//  AIModelSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI

struct AIModelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                    activeSummaryCard
                    providerSelectionSection

                    if modelManager.selectedProvider.isCustomKey {
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

                    if modelManager.enableSearchRefine {
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

    @ViewBuilder
    private func providerRow(provider: AIProviderType) -> some View {
        let isSelected = modelManager.selectedProvider == provider
        Button(action: {
            LBHaptic.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                modelManager.selectedProvider = provider
                testResultMessage = nil
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accent : Color.black.opacity(0.05))
                        .frame(width: 36, height: 36)
                    Image(systemName: provider.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(provider.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        if provider == .cloudGemini {
                            Text("Included")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppTheme.accent))
                        } else if provider.isCustomKey {
                            Text("BYOK")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.06)))
                        }
                    }

                    Text(provider.subtitle)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary.opacity(0.4))
                    .font(.system(size: 20))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent : AppTheme.cardBorder, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Refinement & Reasoning")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 36, height: 36)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Semantic Search Refine")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Extract concepts, time windows, and formats from search queries.")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $modelManager.enableSearchRefine)
                        .labelsHidden()
                        .tint(Color.black)
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
