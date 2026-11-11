// laterbox-ios/laterbox-ios/Views/Components/EarnView.swift
import SwiftUI
import UIKit

/// Native Earn dashboard; matches the simplified, uncluttered web layout.
/// All eligibility, status, and earnings are loaded from LaterBox's authenticated server.
struct EarnView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @StateObject private var coordinator = SyncCoordinator.shared
    @State private var dashboard: EarnDashboardDTO?
    @State private var isLoading = false
    @State private var isJoining = false
    @State private var confirmsAdult = false
    @State private var acceptsTerms = false
    @State private var didCopy = false
    @State private var codeToEdit = ""
    @State private var editingCode = false
    @State private var updatingCode = false
    @State private var errorMessage: String?

    private var primary: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { colorScheme == .dark ? Color(hex: "292D29") : .white }
    private var stroke: Color { InboxAppearance.border(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    }
                    if !coordinator.isAuthenticated {
                        guestPanel
                    } else if let dashboard {
                        if !dashboard.payoutConnected {
                            whopConnectBanner
                        }
                        summary(for: dashboard)
                        if dashboard.referralCode != nil && dashboard.payoutConnected && dashboard.status != "suspended" {
                            referralPanel(for: dashboard)
                        }
                        if dashboard.status == "eligible" {
                            enrollmentPanel(for: dashboard)
                        }
                        earningsPanel(for: dashboard)
                        payoutHistory(for: dashboard)
                        processPanel
                    } else {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(isLoading ? "Checking referral status and balances…" : "Earn isn't available right now.")
                                .foregroundStyle(secondary)
                                .font(.subheadline)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 19)
                .padding(.top, 16)
                .padding(.bottom, 44)
            }
            .background(InboxGrainBackground().ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await refresh() }
            .task(id: coordinator.currentUserId) { await refresh() }
            .alert("Customize referral code", isPresented: $editingCode) {
                TextField("Unique code", text: $codeToEdit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Cancel", role: .cancel) { }
                Button("Save") { Task { await saveCustomCode() } }
            } message: {
                Text("8–32 lowercase characters: letters, numbers, underscores or hyphens. Availability is checked when saving. One change every 30 days.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Earn")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(primary)
            Spacer()
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.bottom, 2)
    }

    private var whopConnectBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STEP 1 · REQUIRED")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundStyle(Color(hex: "526741"))
            Text("Connect your Whop account to unlock referrals")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
            Text("Securely verify your Whop identity first. After connecting, your personal code and shareable referral link will appear here. A paid LaterBox plan is not required.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "536748"))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                if let url = URL(string: "\(LaterBoxAPIService.shared.webUrl)/earn") {
                    openURL(url)
                }
            } label: {
                Text("Connect Whop")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 44)
                    .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 12))
            }
            Text("Referrals and commissions only become active after accepting Earn terms and when the program launches.")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "536748"))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "E6EDB0"), in: RoundedRectangle(cornerRadius: 20))
    }

    private var guestPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Sign in to get started", systemImage: "person.crop.circle")
                .font(.headline)
                .foregroundStyle(primary)
            Text("Sign in to LaterBox to view your referral account, track referrals, and connect Whop.")
                .font(.subheadline)
                .foregroundStyle(secondary)
            Button("Sign in") { coordinator.showingAuthSheet = true }
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(Color(hex: "171711"))
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func summary(for value: EarnDashboardDTO) -> some View {
        HStack(spacing: 10) {
            balanceCard("Pending", cents: value.balances.pendingCents, icon: "clock", desc: "Awaiting hold")
            balanceCard("Available", cents: value.balances.availableCents, icon: "wallet.pass", desc: "Eligible to transfer")
            balanceCard("Paid", cents: value.balances.paidCents, icon: "checkmark.seal", desc: "Transferred")
        }
    }

    private func balanceCard(_ label: String, cents: Int, icon: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(secondary)
            }
            Text(currency(cents))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(primary)
            Text(desc)
                .font(.system(size: 9))
                .foregroundStyle(secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(stroke, lineWidth: 1))
    }

    private func referralPanel(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "gift")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "6B8951"))
                Text("Your referral link and code")
                    .font(.headline)
                    .foregroundStyle(primary)
            }
            Text(value.status == "active" && value.programEnabled
                ? "Share either one and disclose your affiliate relationship."
                : "Your unique code is unlocked by Whop verification. Your code is reserved; referral attribution and commissions will start only when your Earn enrollment and the referral program are active.")
                .font(.subheadline)
                .foregroundStyle(secondary)

            if let url = value.referralUrl {
                VStack(alignment: .leading, spacing: 8) {
                    Text(url)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(primary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(stroke.opacity(0.25), in: RoundedRectangle(cornerRadius: 11))
                    Button {
                        UIPasteboard.general.string = "\(url)\nI may earn a commission if you buy through my link."
                        didCopy = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            didCopy = false
                        }
                    } label: {
                        Label(didCopy ? "Copied" : "Copy link", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "171711"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            HStack(spacing: 12) {
                if let code = value.referralCode {
                    Text("Code: \(code)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(primary)
                    Button("Copy code") {
                        UIPasteboard.general.string = code
                        didCopy = true
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "597442"))

                    Button("Customize") {
                        codeToEdit = code
                        editingCode = true
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "597442"))
                }
                Spacer()
                Text("\(value.referrals) referred")
                    .font(.caption)
                    .foregroundStyle(secondary)
            }
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func enrollmentPanel(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect Whop and activate Earn")
                .font(.headline)
                .foregroundStyle(primary)
            Text("Connect a verified Whop account first. You can join with a Free LaterBox plan; you must also be an adult and accept the terms.")
                .font(.subheadline)
                .foregroundStyle(secondary)

            if value.payoutConnected {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "48613D"))
                    Text("Whop identity verified. Complete the final two checks to join Earn.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "48613D"))
                }
            } else {
                Button("Connect Whop to continue") {
                    if let url = URL(string: "\(LaterBoxAPIService.shared.webUrl)/earn") { openURL(url) }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(hex: "31502A"))
            }

            Toggle("I confirm I am at least 18 years old.", isOn: $confirmsAdult)
                .font(.subheadline)
                .tint(AppTheme.accent)
            Toggle("I accept the affiliate program terms.", isOn: $acceptsTerms)
                .font(.subheadline)
                .tint(AppTheme.accent)

            Button {
                Task { await join() }
            } label: {
                HStack(spacing: 8) {
                    if isJoining { ProgressView().tint(.white) }
                    Text(isJoining ? "Joining…" : "Join Earn")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundStyle(.white)
                .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isJoining || !value.payoutConnected || !confirmsAdult || !acceptsTerms)
            .opacity(isJoining || !value.payoutConnected || !confirmsAdult || !acceptsTerms ? 0.45 : 1)
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func earningsPanel(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Earnings activity").font(.headline)
                Spacer()
                Text("\(value.commissions.count) records")
                    .font(.caption)
                    .foregroundStyle(secondary)
            }
            .foregroundStyle(primary)
            if value.commissions.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "gift")
                        .font(.system(size: 24))
                        .foregroundStyle(secondary)
                    Text("No earnings yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primary)
                    Text("Your verified referrals and commissions will appear here.")
                        .font(.caption)
                        .foregroundStyle(secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(value.commissions, id: \.id) { commission in
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Subscription referral")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primary)
                            Text("\(commission.status.capitalized) · \(dateLabel(commission.createdAt))")
                                .font(.caption)
                                .foregroundStyle(secondary)
                        }
                        Spacer()
                        Text(currency(commission.amountCents))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(primary)
                    }
                }
            }
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func payoutHistory(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payout history")
                    .font(.headline)
                    .foregroundStyle(primary)
                Spacer()
                if value.payoutConnected {
                    Label("Whop verified", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondary)
                }
            }
            if value.payouts.isEmpty {
                Text("No Whop transfers yet. Approved earnings will appear here once transferred.")
                    .font(.subheadline)
                    .foregroundStyle(secondary)
            } else {
                ForEach(value.payouts, id: \.id) { payout in
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Whop balance transfer")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primary)
                            Text("\(payout.status.capitalized) · \(dateLabel(payout.createdAt))")
                                .font(.caption)
                                .foregroundStyle(secondary)
                        }
                        Spacer()
                        Text(currency(payout.amountCents))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(primary)
                    }
                }
            }
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private var processPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How it works").font(.headline).foregroundStyle(primary)
            processRow("1", title: "Connect", detail: "Verify Whop, then share your unique referral link.")
            processRow("2", title: "Trial", detail: "Your new subscriber receives a free month only on a verified trial offer.")
            processRow("3", title: "Qualify", detail: "They must remain subscribed and complete two successful paid billing periods.")
            processRow("4", title: "Earn", detail: "Eligible renewals accrue commission; Whop handles verified payouts.")
            Divider()
            HStack {
                Image(systemName: "shield.checkmark")
                    .font(.caption)
                    .foregroundStyle(secondary)
                Text("Refunded transactions do not qualify. Terms and regional eligibility apply.")
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
            }
            Button {
                if let url = URL(string: "https://whop.com/") { openURL(url) }
            } label: {
                Label("Manage Whop withdrawals", systemImage: "arrow.up.right.square")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primary)
            }
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func processRow(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 28, height: 28)
                .background(AppTheme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(primary)
                Text(detail).font(.caption).foregroundStyle(secondary)
            }
        }
    }

    private func refresh() async {
        guard let token = coordinator.authToken, coordinator.isAuthenticated else {
            dashboard = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            dashboard = try await LaterBoxAPIService.shared.fetchEarnDashboard(token: token)
        } catch {
            if case CloudSyncError.unauthorized = error,
               await coordinator.refreshAuthSession(),
               let newToken = coordinator.authToken {
                do {
                    dashboard = try await LaterBoxAPIService.shared.fetchEarnDashboard(token: newToken)
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func join() async {
        guard confirmsAdult, acceptsTerms, let token = coordinator.authToken else { return }
        isJoining = true
        errorMessage = nil
        defer { isJoining = false }
        do {
            dashboard = try await LaterBoxAPIService.shared.joinEarn(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveCustomCode() async {
        guard let token = coordinator.authToken else { return }
        updatingCode = true
        defer { updatingCode = false }
        do {
            try await LaterBoxAPIService.shared.updateEarnCode(token: token, code: codeToEdit)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func currency(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "USD"))
    }
    private func dateLabel(_ raw: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: raw) else { return raw }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct EarnPanelModifier: ViewModifier {
    let surface: Color
    let stroke: Color
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(stroke, lineWidth: 1))
    }
}
private extension View {
    func earnPanel(surface: Color, stroke: Color) -> some View {
        modifier(EarnPanelModifier(surface: surface, stroke: stroke))
    }
}
