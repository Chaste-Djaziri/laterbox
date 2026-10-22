import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// User-owned, offline library export and non-destructive import.
struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var backupURL: URL?
    @State private var showingBackupImporter = false
    @State private var backupError: String?
    @State private var pendingImport: URL?
    @State private var successBannerMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Your library, your data", systemImage: "externaldrive")
                        .font(.title3.weight(.bold))
                    Text("Export a local backup or restore one anytime. No account or cloud connection required.")
                        .foregroundStyle(AppTheme.textSecondary)
                        .font(.subheadline)
                }
                .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("BACKUP & RESTORE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("Keep a copy of your library, including collections, reminders and locally available attachments. Works in guest mode.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Button {
                                do {
                                    backupURL = try LibraryBackup.export(context: modelContext)
                                } catch { backupError = error.localizedDescription }
                            } label: {
                                Label("Prepare Library Backup", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if let backupURL {
                                ShareLink(item: backupURL) {
                                    Label("Share or Save Backup", systemImage: "square.and.arrow.up.on.square")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            Button {
                                showingBackupImporter = true
                            } label: {
                                Label("Import Library Backup", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Text("Import adds missing items by ID. Existing records are not overwritten or deleted.")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 18)
                if let successBannerMessage {
                    Label(successBannerMessage, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 14)
                }

                Text("Backups include saved items, collections, schedules and attachments available on this device. Store your backup somewhere safe.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(20)
        }
        .background(AppTheme.canvasBackground.ignoresSafeArea())
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
            .fileImporter(isPresented: $showingBackupImporter, allowedContentTypes: [.data, .json, .item]) { result in
                switch result {
                case .success(let url):
                    pendingImport = url
                case .failure(let error):
                    backupError = error.localizedDescription
                }
            }
            .confirmationDialog("Import library backup?", isPresented: Binding(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            )) {
                Button("Merge Into Library") {
                    guard let url = pendingImport else { return }
                    pendingImport = nil
                    do {
                        let result = try LibraryBackup.importArchive(from: url, context: modelContext)
                        triggerSuccessBanner("Imported \(result.items) items, \(result.collections) collections and \(result.attachments) attachments.")
                                            } catch { backupError = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) { pendingImport = nil }
            } message: {
                Text("Only missing item IDs are imported. Your existing library stays unchanged.")
            }
            .alert("Backup & Restore", isPresented: Binding(
                get: { backupError != nil },
                set: { if !$0 { backupError = nil } }
            )) {
                Button("OK") { backupError = nil }
            } message: {
                Text(backupError ?? "")
            }
    }

    private func triggerSuccessBanner(_ message: String) {
        successBannerMessage = message
    }
}
