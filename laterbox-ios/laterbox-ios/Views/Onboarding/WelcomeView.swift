//
//  WelcomeView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var coordinator = SyncCoordinator.shared
    @State private var showingAuthView: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass Ambient Background
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    // Top Bar: Logo & Sign In Button
                    HStack(alignment: .center) {
                        Image("LaterboxLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 38)
                            .accessibilityLabel("Laterbox Logo")

                        Spacer()

                        Button(action: {
                            LBHaptic.light()
                            showingAuthView = true
                        }) {
                            Text("Sign In")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .liquidGlass(cornerRadius: 20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)

                    // Hero Graphic
                    Spacer(minLength: 12)

                    ZStack {
                        // Ambient glow behind hero
                        Circle()
                            .fill(Color.lbEmerald.opacity(0.18))
                            .blur(radius: 50)
                            .frame(width: 240, height: 240)

                        Image("OnboardingHero")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .padding(.horizontal, 20)
                            .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 12)
                    }

                    Spacer(minLength: 16)

                    // Pitch & Headlines
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Save it now.\nRead it later.")
                            .font(.system(size: 34, weight: .black, design: .default))
                            .lineSpacing(-2)
                            .foregroundColor(.primary)

                        Text("Your personal vault for articles, links, files, and notes with real-time cloud sync.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Feature Pills
                        HStack(spacing: 8) {
                            FeaturePill(icon: "bolt.fill", label: "Quick Capture", color: .lbEmerald)
                            FeaturePill(icon: "sparkles", label: "AI Organizer", color: .lbAmber)
                            FeaturePill(icon: "clock.arrow.circlepath", label: "Returns", color: .blue)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)

                    // Action Buttons & Legal
                    VStack(spacing: 12) {
                        // Get Started / Sign In Button
                        Button(action: {
                            LBHaptic.medium()
                            showingAuthView = true
                        }) {
                            HStack {
                                Text("Get Started")
                                    .font(.headline.weight(.bold))
                                Image(systemName: "arrow.right")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.lbEmerald, Color.lbEmerald.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.lbEmerald.opacity(0.35), radius: 14, x: 0, y: 6)
                        }

                        // Continue as Guest Option
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                coordinator.continueAsGuest()
                            }
                        }) {
                            Text("Explore as Guest")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .liquidGlass(cornerRadius: 16)
                        }

                        // Legal Disclaimer
                        HStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .foregroundColor(.secondary.opacity(0.7))
                            Link("Terms", destination: URL(string: "https://laterbox.dev/terms")!)
                                .foregroundColor(.lbEmerald)
                            Text("&")
                                .foregroundColor(.secondary.opacity(0.7))
                            Link("Privacy Policy", destination: URL(string: "https://laterbox.dev/privacy")!)
                                .foregroundColor(.lbEmerald)
                        }
                        .font(.caption2)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showingAuthView) {
                AuthView()
            }
        }
    }
}

private struct FeaturePill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 12)
    }
}

#Preview {
    WelcomeView()
        .preferredColorScheme(.dark)
}
