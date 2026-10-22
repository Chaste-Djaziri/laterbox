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
    @State private var showingPlans = false
    @State private var showingRestore = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Full Page Background Image
                GeometryReader { proxy in
                    Image("WelcomeBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
                .ignoresSafeArea()

                // Contrast Gradient Overlay: Darkens smoothly towards the bottom
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.35),
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar: Logo & Sign In
                    HStack(alignment: .center) {
                        Image("LaterboxLogoWhite")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 38)
                            .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)

                        Spacer()

                        Button(action: {
                            LBHaptic.light()
                            showingAuthView = true
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    Spacer(minLength: 40)

                    // Headline with Reduced Words
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Save it now.\nRead it later.")
                            .font(.system(size: 38, weight: .bold))
                            .lineSpacing(-3)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 2)

                        Text("Your personal knowledge vault.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Account-free access is the primary action.
                    VStack(spacing: 12) {
                        // Enter the local library without registration.
                        Button(action: {
                            LBHaptic.medium()
                            coordinator.continueAsGuest()
                        }) {
                            Text("Continue without account")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
                        }

                        Button {
                            showingRestore = true
                        } label: {
                            Label("Restore an existing library", systemImage: "arrow.down.doc.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .accessibilityIdentifier("welcome.restore")

                        Button("View Pro plans · Purchase or restore") {
                            showingPlans = true
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.75))
                        .accessibilityIdentifier("welcome.plans")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
            .sheet(isPresented: $showingPlans) {
                PlansView(isLiquidGlass: true)
                    .presentationBackground(
                        DeviceGlassSupport.isNativeLiquidGlassSupported
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(Color.black.opacity(0.92))
                    )
            }
            .sheet(isPresented: $showingRestore) {
                NavigationStack { BackupRestoreView() }
            }
            .navigationDestination(isPresented: $showingAuthView) {
                AuthView()
            }
            .preferredColorScheme(.dark)
            .whiteStatusBar()
        }
        .preferredColorScheme(.dark)
        .whiteStatusBar()
    }
}

#Preview {
    WelcomeView()
}
