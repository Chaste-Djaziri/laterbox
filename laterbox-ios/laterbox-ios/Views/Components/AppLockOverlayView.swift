//
//  AppLockOverlayView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import SwiftUI
import LocalAuthentication

public struct AppLockOverlayView: View {
    @ObservedObject private var lockManager = AppLockManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            // Ambient Liquid Glass Frosted Backdrop
            LiquidGlassBackground()
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Security Icon with Specular Glow
                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                // Typography
                VStack(spacing: 8) {
                    Text("LaterBox is Locked")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Unlock with \(lockManager.biometryName) to access your saved links and notes.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Error feedback if any
                if let error = lockManager.authenticationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Primary Unlock Button
                Button(action: {
                    LBHaptic.medium()
                    Task {
                        await lockManager.unlockApp()
                    }
                }) {
                    HStack(spacing: 10) {
                        if lockManager.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: lockManager.biometryIconName)
                                .font(.system(size: 18, weight: .semibold))
                            Text("Unlock with \(lockManager.biometryName)")
                                .font(.headline.weight(.bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.darkSurface)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(lockManager.isAuthenticating)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            // Automatically prompt for biometrics on screen display
            Task {
                // Short delay to allow window transition to complete smoothly
                try? await Task.sleep(nanoseconds: 200_000_000)
                await lockManager.unlockApp()
            }
        }
    }
}
