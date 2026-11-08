//
//  AboutSettingsView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 22.10.26.
//

import SwiftUI

struct AboutSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let websiteURL = URL(string: "https://laterbox.dev")!
    private let privacyURL = URL(string: StoreKitManager.privacyPolicyUrl)!
    private let termsURL = URL(string: StoreKitManager.termsOfServiceUrl)!

    var body: some View {
        ZStack {
            InboxGrainBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    appIdentityCard
                    detailsCard
                    NavigationLink(destination: CheckForUpdatesView()) {
                        HStack {
                            Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Text(AppVersion.currentVersion).font(.caption.monospaced())
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                        .padding(18)
                        .settingsCard(for: colorScheme, cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                    linksCard
                }
                .padding(20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appIdentityCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                .frame(width: 72, height: 72)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 5) {
                Text("LaterBox")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                Text("Save now. Explore later.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
            }

            Text(AppVersion.displayString)
                .font(.caption.monospaced())
                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(SettingsAppearance.inset(for: colorScheme).opacity(0.8), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .settingsCard(for: colorScheme, cornerRadius: 22)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About the app")
                .font(.headline)
                .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))

            Text("LaterBox helps you save links, articles, and content so you can revisit what matters whenever you're ready.")
                .font(.system(size: 15))
                .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(SettingsAppearance.border(for: colorScheme))

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
                Text("Chaste Djaziri")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                Text("Independent Developer")
                    .font(.subheadline)
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .settingsCard(for: colorScheme, cornerRadius: 20)
    }

    private var linksCard: some View {
        VStack(spacing: 0) {
            linkRow(title: "Website", icon: "globe", url: websiteURL)
            Divider().overlay(SettingsAppearance.border(for: colorScheme)).padding(.leading, 48)
            linkRow(title: "Privacy Policy", icon: "hand.raised", url: privacyURL)
            Divider().overlay(SettingsAppearance.border(for: colorScheme)).padding(.leading, 48)
            linkRow(title: "Terms of Service", icon: "doc.text", url: termsURL)
        }
        .settingsCard(for: colorScheme, cornerRadius: 18)
    }

    private func linkRow(title: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsAppearance.textPrimary(for: colorScheme))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsAppearance.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
