//
//  AccountSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI

public struct AccountSettingsView: View {
    @ObservedObject private var coordinator = SyncCoordinator.shared
    @State private var showingAuthSheet = false
    @State private var showingSignOutAlert = false

    public init() {}

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 76, height: 76)
                            Image(systemName: "person.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        VStack(spacing: 4) {
                            if let email = coordinator.currentUserEmail {
                                Text(email)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)

                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(coordinator.isProUser ? "LaterBox Pro Active" : "Free Cloud Account")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            } else {
                                Text("Guest Mode")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text("Local saving active • Sign in for cloud sync")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Account Status & Info Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Account Details")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(coordinator.isAuthenticated ? Color.green : Color.orange)
                                        .frame(width: 8, height: 8)
                                    Text(coordinator.isAuthenticated ? "Signed In" : "Local Guest")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                Text("Account Type")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(coordinator.isProUser ? "Pro" : (coordinator.isAuthenticated ? "Free" : "Guest"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack {
                                Text("Cloud Synchronization")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(coordinator.hasCloudPro ? "Enabled (Multi-device)" : "Local Only")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(coordinator.hasCloudPro ? Color.green : AppTheme.textSecondary)
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
                    }

                    // Authentication Action
                    if coordinator.currentUserEmail == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sign In or Register")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Button(action: {
                                LBHaptic.light()
                                showingAuthSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.headline)
                                    Text("Sign In to LaterBox")
                                        .font(.headline.weight(.bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(AppTheme.darkSurface)
                                )
                            }
                            .buttonStyle(.plain)

                            Text("Signing in lets you link browser extensions, access your inbox on the web, and upgrade to Pro cloud sync.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineSpacing(2)
                                .padding(.horizontal, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Session")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Button(action: {
                                LBHaptic.light()
                                showingSignOutAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Sign Out")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Account & Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuthSheet) {
            NavigationStack {
                AuthView()
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) { coordinator.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local items will be safely kept on this device.")
        }
    }
}
