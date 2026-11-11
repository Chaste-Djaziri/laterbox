//
//  ErrorDiagnosticsSheet.swift
//  laterbox-ios
//
//  A comprehensive sheet for inspecting system diagnostics, error details,
//  and sharing reports via ShareLink, clipboard, or support submission.
//

import SwiftUI
import SwiftData

public struct ErrorDiagnosticsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    private let specificError: String?
    private let activeScreen: String?

    @State private var report: AppDiagnosticReport?
    @State private var showingSupport = false
    @State private var showCopiedAlert = false

    public init(specificError: String? = nil, activeScreen: String? = nil) {
        self.specificError = specificError
        self.activeScreen = activeScreen
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                InboxGrainBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if let rep = report {
                            // Active error callout
                            if rep.hasError, let err = rep.activeErrorMessage {
                                errorCallout(err)
                            }

                            // Quick actions
                            actionButtons(rep)

                            // Diagnostic detail sections
                            diagnosticsSection(
                                title: "DEVICE & SYSTEM",
                                icon: "iphone",
                                rows: [
                                    ("Device", rep.deviceMarketingName),
                                    ("Hardware", rep.deviceHardwareSummary),
                                    ("OS Version", "iOS \(rep.iosVersion)"),
                                    ("App Version", "\(rep.appVersion) (\(rep.buildNumber))"),
                                    ("Screen Name", rep.activeScreen),
                                    ("Display", rep.screenResolution),
                                    ("Locale / TimeZone", "\(rep.locale) · \(rep.timeZone)")
                                ]
                            )

                            diagnosticsSection(
                                title: "CLOUD SYNC & NETWORK",
                                icon: "arrow.triangle.2.circlepath.icloud",
                                rows: [
                                    ("Sync State", rep.cloudSyncState),
                                    ("Last Sync", rep.lastSyncTime),
                                    ("Pending Changes", "Push: \(rep.pendingPushes) · Pull: \(rep.pendingPulls)"),
                                    ("Activity", rep.activeSyncOperation),
                                    ("Supabase API", rep.apiEndpoint),
                                    ("Web Host", rep.webEndpoint)
                                ]
                            )

                            diagnosticsSection(
                                title: "ACCOUNT & STORAGE",
                                icon: "person.crop.circle",
                                rows: [
                                    ("Account", rep.userEmail),
                                    ("Tier", "\(rep.accountTier.capitalized) (Pro: \(rep.isPro ? "Yes" : "No"))"),
                                    ("Session", rep.sessionExpired ? "Expired" : "Valid"),
                                    ("Cloud Storage", "\(rep.storageUsedLabel) / \(rep.storageLimitLabel)"),
                                    ("Quota Used", rep.storagePercent),
                                    ("Storage Health", rep.storageLevel)
                                ]
                            )

                            diagnosticsSection(
                                title: "LOCAL VAULT",
                                icon: "tray.full",
                                rows: [
                                    ("Total Items", "\(rep.totalVaultItems)"),
                                    ("Inbox", "\(rep.inboxItems)"),
                                    ("Saved / Kept", "\(rep.savedItems)"),
                                    ("Archived", "\(rep.archivedItems)"),
                                    ("Recently Deleted", "\(rep.deletedItems)")
                                ]
                            )
                        } else {
                            ProgressView("Compiling diagnostics…")
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Diagnostics & Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if let rep = report {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(
                            item: rep.markdownExport,
                            subject: Text("LaterBox Diagnostics (\(rep.activeScreen))"),
                            message: Text(rep.formattedSummary)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSupport) {
                if let rep = report {
                    NavigationStack {
                        SupportRequestView(
                            initialSubject: rep.hasError ? "Error report: \(rep.activeScreen)" : "Feedback & Diagnostics",
                            initialMessage: rep.formattedSummary
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showingSupport = false }
                            }
                        }
                    }
                }
            }
            .alert("Copied to Clipboard", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Full diagnostic report and error details copied. You can paste them into an email or support ticket.")
            }
            .onAppear {
                loadReport()
            }
        }
    }

    private func loadReport() {
        self.report = AppDiagnosticsManager.shared.generateReport(
            context: modelContext,
            specificError: specificError,
            activeScreen: activeScreen
        )
    }

    // MARK: - Error Callout
    private func errorCallout(_ errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "D49431"))
                    .font(.system(size: 16, weight: .bold))
                Text("Active Issue Detected")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                Spacer()
            }

            Text(errorMessage)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SettingsAppearance.inset(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
                .textSelection(.enabled)

            HStack(spacing: 12) {
                Button {
                    LBHaptic.light()
                    AppDiagnosticsManager.shared.copyToClipboard(errorMessage)
                    showCopiedAlert = true
                } label: {
                    Label("Copy Error", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)

                ShareLink(item: errorMessage) {
                    Label("Share Error", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "D49431").opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: "D49431").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private func actionButtons(_ rep: AppDiagnosticReport) -> some View {
        VStack(spacing: 10) {
            Button {
                LBHaptic.medium()
                showingSupport = true
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Report to LaterBox Support")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(SettingsAppearance.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                ShareLink(
                    item: rep.markdownExport,
                    subject: Text("LaterBox Diagnostics Report"),
                    message: Text(rep.formattedSummary)
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Details")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SettingsAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(SettingsAppearance.border(for: colorScheme), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    LBHaptic.success()
                    AppDiagnosticsManager.shared.copyToClipboard(rep.markdownExport)
                    showCopiedAlert = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Report")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SettingsAppearance.surface(for: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(SettingsAppearance.border(for: colorScheme), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section Card
    private func diagnosticsSection(title: String, icon: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { idx in
                    let (label, val) = rows[idx]
                    HStack(alignment: .top, spacing: 12) {
                        Text(label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SettingsAppearance.textSecondary(for: colorScheme))
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(val)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SettingsAppearance.textPrimary(for: colorScheme))
                            .multilineTextAlignment(.trailing)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if idx < rows.count - 1 {
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
            .settingsCard(for: colorScheme, cornerRadius: 14)
        }
    }
}
