import SwiftUI

struct AIModelSettingsView: View {
    @ObservedObject private var modelManager = LaterAIModelManager.shared

    @State private var testingProvider: AIProviderType? = nil
    @State private var lastTestedProvider: AIProviderType? = nil
    @State private var testResultMessage: String? = nil
    @State private var isTestingSuccess: Bool = false
    @State private var showMissingKeyAlert: Bool = false
    @State private var missingKeyProvider: AIProviderType = .bazaarlink

    private let bazaarlinkModels = [
        ("qwen/qwen3.7-flash", "Qwen 3.7 Flash · 1M Context (Free)"),
        ("deepseek/deepseek-v4-flash-0731free", "DeepSeek V4 Flash · 1M Context (Free)"),
        ("nvidia/nemotron-3.5-lightning-free", "Nemotron 3.5 Lightning (Free)"),
        ("reflection/beam-free", "Beam Free · 1M Context (Free)")
    ]

    private let geminiModels = [
        ("gemini-2.5-flash", "Gemini 2.5 Flash"),
        ("gemini-3.5-flash-lite", "Gemini 3.5 Flash Lite"),
        ("gemini-3.8-flash", "Gemini 3.8 Flash")
    ]

    private let openaiModels = [
        ("gpt-4o-mini", "GPT-4o Mini · Fast & Affordable"),
        ("gpt-4o", "GPT-4o · Flagship Omni Intelligence"),
        ("o3-mini", "o3-mini · Advanced Reasoning")
    ]

    private let claudeModels = [
        ("claude-3-5-haiku-20241022", "Claude 3.5 Haiku · Fast & Capable"),
        ("claude-3-5-sonnet-20241022", "Claude 3.5 Sonnet · Highest Quality"),
        ("claude-3-7-sonnet", "Claude 3.7 Sonnet · Hybrid Reasoning")
    ]

    var body: some View {
        ZStack {
            LiquidGlassBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Intelligence Engine", systemImage: "sparkles")
                            .font(.title2.bold())
                        Text("On-device intelligence, free cloud models, and AI assistants for capture and search.")
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
                                provider: .onDevice,
                                title: "On-Device Neural Engine",
                                subtitle: "Apple Intelligence hardware · Zero data leaves device",
                                icon: "cpu"
                            )
                        }

                        engineOptionRow(
                            provider: .local,
                            title: "Local responses",
                            subtitle: "Deterministic offline rules · 100% private",
                            icon: "wand.and.stars"
                        )

                        engineOptionRow(
                            provider: .bazaarlink,
                            title: "BazaarLink (Free AI)",
                            subtitle: "Qwen 3.7 Flash / DeepSeek V4 · Requires free key",
                            icon: "bolt.shield.fill"
                        )

                        engineOptionRow(
                            provider: .gemini,
                            title: "Google Gemini",
                            subtitle: "Google Gemini 2.5 / 3.5 Flash · Requires API key",
                            icon: "sparkles"
                        )

                        engineOptionRow(
                            provider: .openai,
                            title: "OpenAI GPT",
                            subtitle: "GPT-4o / GPT-4o-mini · Requires API key",
                            icon: "brain.head.profile"
                        )

                        engineOptionRow(
                            provider: .claude,
                            title: "Anthropic Claude",
                            subtitle: "Claude 3.5 Sonnet / Haiku · Requires API key",
                            icon: "bubble.left.and.text.bubble.right.fill"
                        )
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - BazaarLink Free AI Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("BazaarLink Free AI", systemImage: "bolt.shield.fill")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Text("Free Tier · Own Key")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "0284C7"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "E0F2FE"), in: Capsule())
                        }

                        Text("Drop-in OpenAI-compatible API with free Qwen 3.7 Flash and DeepSeek V4 models. Requires no credit card.")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            Picker("Model", selection: $modelManager.bazaarlinkModel) {
                                ForEach(bazaarlinkModels, id: \.0) { model in
                                    Text(model.1).tag(model.0)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key (BAZAARLINK_API_KEY)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            HStack {
                                SecureField("Enter BazaarLink API key", text: $modelManager.bazaarlinkApiKey)
                                    .font(.system(size: 14))

                                if !modelManager.bazaarlinkApiKey.isEmpty {
                                    Button {
                                        modelManager.bazaarlinkApiKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            Button {
                                runTest(for: .bazaarlink)
                            } label: {
                                HStack(spacing: 5) {
                                    if testingProvider == .bazaarlink {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text("Test Connection")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(testingProvider != nil)

                            Link(destination: URL(string: "https://bazaarlink.ai/keys")!) {
                                Text("Get Free Key ↗")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "0284C7"))
                            }
                        }

                        if lastTestedProvider == .bazaarlink, let testResultMessage, testingProvider == nil {
                            Text(testResultMessage)
                                .font(.caption.bold())
                                .foregroundColor(isTestingSuccess ? Color(red: 22/255, green: 130/255, blue: 60/255) : Color(red: 220/255, green: 38/255, blue: 38/255))
                                .padding(.top, 2)
                        }
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - Google Gemini Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Google Gemini", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Text("Gemini API · Own Key")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "4338CA"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "EEF2FF"), in: Capsule())
                        }

                        Text("Multimodal cloud intelligence for complex task and media reasoning. Requires your Google AI Studio key.")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            Picker("Model", selection: $modelManager.geminiModel) {
                                ForEach(geminiModels, id: \.0) { model in
                                    Text(model.1).tag(model.0)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key (GEMINI_API_KEY)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            HStack {
                                SecureField("Enter Google Gemini API key", text: $modelManager.geminiApiKey)
                                    .font(.system(size: 14))

                                if !modelManager.geminiApiKey.isEmpty {
                                    Button {
                                        modelManager.geminiApiKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            Button {
                                runTest(for: .gemini)
                            } label: {
                                HStack(spacing: 5) {
                                    if testingProvider == .gemini {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text("Test Connection")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(testingProvider != nil)

                            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                                Text("Get Gemini Key ↗")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "4338CA"))
                            }
                        }

                        if lastTestedProvider == .gemini, let testResultMessage, testingProvider == nil {
                            Text(testResultMessage)
                                .font(.caption.bold())
                                .foregroundColor(isTestingSuccess ? Color(red: 22/255, green: 130/255, blue: 60/255) : Color(red: 220/255, green: 38/255, blue: 38/255))
                                .padding(.top, 2)
                        }
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - OpenAI GPT Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("OpenAI GPT", systemImage: "brain.head.profile")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Text("OpenAI API · Own Key")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "0F766E"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "CCFBF1"), in: Capsule())
                        }

                        Text("Industry-standard GPT-4o, GPT-4o Mini, and o3-mini models. Requires your OpenAI API key.")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            Picker("Model", selection: $modelManager.openaiModel) {
                                ForEach(openaiModels, id: \.0) { model in
                                    Text(model.1).tag(model.0)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key (OPENAI_API_KEY)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            HStack {
                                SecureField("sk-...", text: $modelManager.openaiApiKey)
                                    .font(.system(size: 14))

                                if !modelManager.openaiApiKey.isEmpty {
                                    Button {
                                        modelManager.openaiApiKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            Button {
                                runTest(for: .openai)
                            } label: {
                                HStack(spacing: 5) {
                                    if testingProvider == .openai {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text("Test Connection")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(testingProvider != nil)

                            Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                                Text("Get OpenAI Key ↗")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "0F766E"))
                            }
                        }

                        if lastTestedProvider == .openai, let testResultMessage, testingProvider == nil {
                            Text(testResultMessage)
                                .font(.caption.bold())
                                .foregroundColor(isTestingSuccess ? Color(red: 22/255, green: 130/255, blue: 60/255) : Color(red: 220/255, green: 38/255, blue: 38/255))
                                .padding(.top, 2)
                        }
                    }
                    .padding(18)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                    // MARK: - Anthropic Claude Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Anthropic Claude", systemImage: "bubble.left.and.text.bubble.right.fill")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Text("Claude API · Own Key")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "C2410C"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "FFEDD5"), in: Capsule())
                        }

                        Text("State-of-the-art Claude 3.5 Sonnet, 3.5 Haiku, and 3.7 Sonnet. Requires your Anthropic console key.")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            Picker("Model", selection: $modelManager.claudeModel) {
                                ForEach(claudeModels, id: \.0) { model in
                                    Text(model.1).tag(model.0)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key (ANTHROPIC_API_KEY)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.textSecondary)

                            HStack {
                                SecureField("sk-ant-...", text: $modelManager.claudeApiKey)
                                    .font(.system(size: 14))

                                if !modelManager.claudeApiKey.isEmpty {
                                    Button {
                                        modelManager.claudeApiKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                        }

                        HStack(spacing: 12) {
                            Button {
                                runTest(for: .claude)
                            } label: {
                                HStack(spacing: 5) {
                                    if testingProvider == .claude {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text("Test Connection")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(testingProvider != nil)

                            Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                                Text("Get Claude Key ↗")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "C2410C"))
                            }
                        }

                        if lastTestedProvider == .claude, let testResultMessage, testingProvider == nil {
                            Text(testResultMessage)
                                .font(.caption.bold())
                                .foregroundColor(isTestingSuccess ? Color(red: 22/255, green: 130/255, blue: 60/255) : Color(red: 220/255, green: 38/255, blue: 38/255))
                                .padding(.top, 2)
                        }
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
                }
                .padding(20)
            }
        }
        .navigationTitle("Later AI Models")
        .navigationBarTitleDisplayMode(.inline)
        .alert("API Key Required", isPresented: $showMissingKeyAlert) {
            Button("Configure Key") {
                modelManager.selectedProvider = missingKeyProvider
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To activate \(missingKeyProvider.displayName), please enter your own API key in the configuration section below.\n\nOn-Device Model and Local responses are always free and work completely offline without an API key.")
        }
    }

    private func handleSelectProvider(_ provider: AIProviderType) {
        if provider.isCustomKey && !modelManager.hasApiKey(for: provider) {
            missingKeyProvider = provider
            showMissingKeyAlert = true
        } else {
            modelManager.selectedProvider = provider
        }
    }

    private func runTest(for provider: AIProviderType) {
        testingProvider = provider
        lastTestedProvider = provider
        testResultMessage = nil
        Task {
            do {
                let res = try await modelManager.testConnection(for: provider)
                await MainActor.run {
                    testResultMessage = res
                    isTestingSuccess = true
                    testingProvider = nil
                }
            } catch {
                await MainActor.run {
                    testResultMessage = error.localizedDescription
                    isTestingSuccess = false
                    testingProvider = nil
                }
            }
        }
    }

    private func engineOptionRow(provider: AIProviderType, title: String, subtitle: String, icon: String) -> some View {
        let isSelected = modelManager.selectedProvider == provider
        let hasKey = modelManager.hasApiKey(for: provider)

        return Button {
            handleSelectProvider(provider)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 38, height: 38)
                    .background(isSelected ? AppTheme.accent : Color.black.opacity(0.05), in: Circle())
                    .foregroundColor(.black)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        if provider.isCustomKey {
                            Text(hasKey ? "Key Set" : "Key Required")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(hasKey ? Color.green.opacity(0.12) : Color.orange.opacity(0.15))
                                )
                                .foregroundColor(hasKey ? Color(red: 22/255, green: 130/255, blue: 60/255) : Color.orange)
                        } else {
                            Text("Offline")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.06)))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

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
