import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import LocalAuthentication

struct BackupRestoreView: View {
    var recoveryOnly = false
    @Environment(\.modelContext) private var modelContext
    @State private var backupURL: URL?
    @State private var showingImporter = false
    @State private var pendingImport: URL?
    @State private var password = ""
    @State private var confirmation = ""
    @State private var exportPassword = ""
    @State private var exporting = false
    @State private var importing = false
    @State private var authenticateExport = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(recoveryOnly ? "Restore your library" : "Your library, your data", systemImage: "externaldrive.fill")
                        .foregroundStyle(AppTheme.textPrimary)
                        .font(.title2.bold())
                    Text(recoveryOnly ? "Have a LaterBox backup? Import your saved items and collections before continuing." : "Securely move your saved items, collections, reminders, and available attachments between devices.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 10)

                if !recoveryOnly {
                VStack(alignment: .leading, spacing: 13) {
                    Label("Encrypted export", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Create a backup protected by your own recovery password. Device authentication is required before exporting.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    SecureField("Recovery password (8+ characters)", text: $password)
                        .textContentType(.newPassword)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(13)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                    SecureField("Confirm recovery password", text: $confirmation)
                        .textContentType(.newPassword)
                        .padding(13)
                        .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 12))
                    Button {
                        Task { await prepareExport() }
                    } label: {
                        HStack(spacing: 10) {
                            if exporting { ProgressView().tint(.black) }
                            else { Image(systemName: "lock.doc.fill") }
                            Text(exporting ? "Preparing encrypted backup…" : "Create Secure Backup")
                            Spacer()
                            if !exporting { Image(systemName: "arrow.right") }
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .padding(16)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(exporting || password.count < 8 || password != confirmation)
                    if let backupURL {
                        ShareLink(item: backupURL) {
                            Label("Save Backup to Files or iCloud Drive", systemImage: "square.and.arrow.up.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(15)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(18)
                .liquidGlassCard(cornerRadius: 20)

                }

                VStack(alignment: .leading, spacing: 13) {
                    Label("Restore from backup", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Choose a .laterbox file and enter its recovery password. Existing items are kept; missing items are merged.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Button { showingImporter = true } label: {
                        Label("Choose Backup File", systemImage: "folder.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 14))
                    }
                    if pendingImport != nil {
                        SecureField("Backup recovery password", text: $exportPassword)
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(13)
                            .background(AppTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 12))
                        Button {
                            Task { await performImport() }
                        } label: {
                            HStack {
                                if importing { ProgressView().tint(.black) }
                                else { Image(systemName: "arrow.down.to.line.compact") }
                                Text(importing ? "Restoring library…" : "Import and Merge")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(importing || exportPassword.isEmpty)
                    }
                }
                .padding(18)
                .liquidGlassCard(cornerRadius: 20)

                if let successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.textPrimary)
                        .font(.subheadline)
                }
                if !recoveryOnly {
                Text("Keep your password somewhere safe: LaterBox cannot recover it. Backups left only inside the app are lost if the app is deleted. Save a copy to Files, iCloud Drive, or another storage provider.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(20)
        }
        .background(AppTheme.canvasBackground.ignoresSafeArea())
        .tint(Color.blue)
        .navigationTitle(recoveryOnly ? "Restore Backup" : "Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, .light)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.data, .json, .item]) { result in
            switch result {
            case .success(let file):
                pendingImport = file
                successMessage = nil
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
        .alert("Backup & Restore", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func prepareExport() async {
        guard password.count >= 8, password == confirmation else { return }
        exporting = true
        defer { exporting = false }
        let authentication = LAContext()
        var reasonError: NSError?
        guard authentication.canEvaluatePolicy(.deviceOwnerAuthentication, error: &reasonError) else {
            errorMessage = reasonError?.localizedDescription ?? "Set up Face ID, Touch ID or a device passcode to export backups."
            return
        }
        do {
            let authorized = try await authentication.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to export your private LaterBox library")
            guard authorized else { return }
            backupURL = try LibraryBackup.export(context: modelContext, password: password)
            password = ""
            confirmation = ""
            successMessage = "Secure backup created. Save it outside the app to keep it safe."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func performImport() async {
        guard let file = pendingImport, !exportPassword.isEmpty else { return }
        importing = true
        defer { importing = false }
        do {
            let result = try LibraryBackup.importArchive(
                from: file, context: modelContext, password: exportPassword)
            pendingImport = nil
            exportPassword = ""
            successMessage = "Imported \(result.items) items, \(result.collections) collections, \(result.attachments) attachments. Skipped \(result.skipped) existing items."
        } catch {
            errorMessage = "Unable to open backup. Check your recovery password and file. \(error.localizedDescription)"
        }
    }
}
