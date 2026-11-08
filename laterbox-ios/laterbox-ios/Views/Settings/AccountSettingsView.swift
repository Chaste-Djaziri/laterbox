//
//  AccountSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

public struct AccountSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @State private var showingAuthSheet = false
    @State private var showingSignOutAlert = false
    @State private var showingExitGuestAlert = false
    @State private var appleLinkMessage: String?

    public init() {}

    public var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    identityCard
                    accountDetailsCard
                    accessCard
                }
                .padding(20)
            }
        }
        .navigationTitle("Account & Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuthSheet) {
            NavigationStack { AuthView() }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) { coordinator.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local items will be safely kept on this device.")
        }
        .alert("Exit Guest Mode", isPresented: $showingExitGuestAlert) {
            Button("Exit & Clear Data", role: .destructive) {
                coordinator.exitGuest(context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Exiting guest mode will clear all items saved on this device during this guest session.")
        }
    }

    private var identityCard: some View {
        VStack(spacing: 14) {
            Image(systemName: coordinator.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(SettingsAppearance.onAccent)
                .frame(width: 76, height: 76)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 23, style: .continuous))

            VStack(spacing: 6) {
                Text(coordinator.currentUserEmail ?? "Guest Mode")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(coordinator.isAuthenticated
                     ? (coordinator.isProUser ? "LaterBox Pro Active" : "Free Cloud Account")
                     : "Your saved items stay on this device")
                    .font(.subheadline)
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            Label(coordinator.isAuthenticated ? "Signed in" : "Local guest",
                  systemImage: coordinator.isAuthenticated ? "checkmark.seal.fill" : "internaldrive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(SettingsAppearance.inset(for: colorScheme).opacity(0.8), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 26)
        .settingsCard(for: colorScheme, cornerRadius: 22)
    }

    private var accountDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Account details")
                .font(.headline)
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)

            detailRow("Status", value: coordinator.isAuthenticated ? "Signed In" : "Local Guest")
            rowDivider
            detailRow("Plan", value: coordinator.isProUser ? "Pro" : (coordinator.isAuthenticated ? "Free" : "Guest"))
            rowDivider
            detailRow("Cloud Sync", value: coordinator.hasCloudPro ? "Multi-device enabled" : "Local only")
        }
        .padding(.bottom, 4)
        .settingsCard(for: colorScheme, cornerRadius: 20)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(SettingsAppearance.border(for: colorScheme))
            .padding(.leading, 18)
    }

    private var accessCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(coordinator.isAuthenticated ? "Connected accounts" : "Get more from LaterBox")
                .font(.headline)
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

            if coordinator.isAuthenticated {
                Text("Connect your Apple identity to your existing LaterBox account.")
                    .font(.subheadline)
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))

                SignInWithAppleButton(.continue, onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                }, onCompletion: handleAppleLinkResult)
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: 375)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if let appleLinkMessage {
                    Text(appleLinkMessage)
                        .font(.caption)
                        .foregroundStyle(appleLinkMessage.hasPrefix("Connected") ? Color.green : Color.red)
                }

                Divider().overlay(SettingsAppearance.border(for: colorScheme))
                sessionButton(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right") {
                    showingSignOutAlert = true
                }
            } else {
                Text("Sign in to access your saved items on the web, connect extensions, and enable Pro cloud sync.")
                    .font(.subheadline)
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    LBHaptic.light()
                    showingAuthSheet = true
                } label: {
                    Label("Sign In to LaterBox", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppTheme.darkSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Divider().overlay(SettingsAppearance.border(for: colorScheme))
                sessionButton(title: "Exit Guest Mode", icon: "rectangle.portrait.and.arrow.right") {
                    showingExitGuestAlert = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .settingsCard(for: colorScheme, cornerRadius: 20)
    }

    private func sessionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            LBHaptic.medium()
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func handleAppleLinkResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
            appleLinkMessage = "Apple connection failed. Please try again."
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  let sessionToken = coordinator.authToken else {
                appleLinkMessage = "Apple did not return a valid sign-in token."
                return
            }
            Task {
                do {
                    let result = try await LaterBoxAPIService.shared.signInWithApple(
                        identityToken: identityToken,
                        sessionToken: sessionToken
                    )
                    guard result.userId == coordinator.currentUserId else {
                        await MainActor.run { appleLinkMessage = "This Apple account belongs to another LaterBox account." }
                        return
                    }
                    await MainActor.run { appleLinkMessage = "Connected to Apple successfully." }
                } catch {
                    await MainActor.run { appleLinkMessage = "Could not connect Apple. Please try again." }
                }
            }
        }
    }
}
