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
                // Main App Background #F7F5EE
                Color.lbBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar: Logo & Sign In
                    HStack(alignment: .center) {
                        Image("LaterboxLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 34)

                        Spacer()

                        Button(action: {
                            LBHaptic.light()
                            showingAuthView = true
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    Spacer(minLength: 8)

                    // Big Hero Illustration
                    Image("OnboardingHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 380)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 16)

                    // Headline with Reduced Words
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Save it now.\nRead it later.")
                            .font(.system(size: 36, weight: .bold))
                            .lineSpacing(-3)
                            .foregroundColor(.black)

                        Text("Your personal knowledge vault.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Action Buttons: Black Continue & Guest Option
                    VStack(spacing: 12) {
                        // Solid Black Continue Button
                        Button(action: {
                            LBHaptic.medium()
                            showingAuthView = true
                        }) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Continue Without Account
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                coordinator.continueAsGuest()
                            }
                        }) {
                            Text("Continue without account")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color.black.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }

                        // Legal Disclaimer
                        HStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .foregroundColor(Color.black.opacity(0.45))
                            Link("Terms", destination: URL(string: "https://laterbox.dev/terms")!)
                                .foregroundColor(.black)
                                .underline()
                            Text("&")
                                .foregroundColor(Color.black.opacity(0.45))
                            Link("Privacy Policy", destination: URL(string: "https://laterbox.dev/privacy")!)
                                .foregroundColor(.black)
                                .underline()
                        }
                        .font(.caption2)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showingAuthView) {
                AuthView()
            }
        }
    }
}

#Preview {
    WelcomeView()
}
