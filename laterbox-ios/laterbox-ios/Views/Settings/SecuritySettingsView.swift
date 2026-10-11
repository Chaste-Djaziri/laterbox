//
//  SecuritySettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 11.10.26.
//

import SwiftUI

public struct SecuritySettingsView: View {
    @ObservedObject private var lockManager = AppLockManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Status Card
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(lockManager.isAppLockEnabled ? AppTheme.accent : Color.black.opacity(0.04))
                                .frame(width: 72, height: 72)
                            Image(systemName: lockManager.biometryIconName)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        VStack(spacing: 4) {
                            Text(lockManager.isAppLockEnabled ? "\(lockManager.biometryName) Active" : "App Lock Disabled")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(lockManager.isAppLockEnabled ? "LaterBox requires authentication to unlock" : "Anyone with access to your device can open LaterBox")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    // Biometric Configuration Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("App Lock Configuration")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(spacing: 14) {
                            // Biometric Toggle Row
                            HStack(alignment: .center) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accent)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: lockManager.biometryIconName)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Require \(lockManager.biometryName)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text(lockManager.isAppLockEnabled ? "Enabled" : "Disabled")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { lockManager.isAppLockEnabled },
                                    set: { _ in
                                        Task {
                                            await lockManager.toggleAppLock()
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(Color.black)
                            }

                            if let error = lockManager.authenticationError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if lockManager.isAppLockEnabled {
                                Divider().background(AppTheme.cardBorder)

                                // Immediate Lock Button
                                Button(action: {
                                    LBHaptic.medium()
                                    lockManager.lockAppIfNeeded()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                        Text("Lock LaterBox Now")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppTheme.accent)
                                    )
                                }
                                .buttonStyle(.plain)
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

                    // Privacy Architecture
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Zero-Tracking Privacy Guarantee")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Encrypted Local Vault")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("Items, highlights, and offline attachments are stored securely in Apple SwiftData and Keychain-protected sandboxes.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }

                            Divider().background(AppTheme.cardBorder)

                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No Third-Party Trackers")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("LaterBox never sells your data, embeds ad libraries, or monitors your browsing habits.")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Security & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
