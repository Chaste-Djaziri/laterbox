// laterbox-ios/laterbox-ios/Views/Components/EarnView.swift
import SwiftUI
import UIKit

/// Native Earn dashboard; all eligibility, status and money are loaded from
/// LaterBox's authenticated server, never calculated or credited on-device.
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
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
                    }
                    if !coordinator.isAuthenticated {
                        guestPanel
                    } else if let dashboard {
                        summary(for: dashboard)
                        eligibilityPanel(for: dashboard)
                        if dashboard.referralCode != nil && dashboard.status == "active" && dashboard.payoutConnected { referralPanel(for: dashboard) }
                        if dashboard.status == "eligible" { enrollmentPanel(for: dashboard) }
                        earningsPanel(for: dashboard)
                        payoutHistory(for: dashboard)
                        processPanel
                    } else {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(isLoading ? "Checking membership and earnings…" : "Earn isn't available right now.")
                                .foregroundStyle(secondary)
                                .font(.subheadline)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 19)
                .padding(.top, 22)
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
                Text("4–32 lowercase letters, numbers, hyphens or underscores. Codes must be unique and can change once every 30 days.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                Text("LATERBOX EARN")
                    .tracking(1)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: "2B3E20"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.accent, in: Capsule())
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Share more.\nEarn more.")
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-1.4)
                        .foregroundStyle(primary)
                    Text("Invite new members to LaterBox. See your referrals, commissions and payouts all in one place.")
                        .font(.system(size: 14))
                        .foregroundStyle(secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                Spacer(minLength: 8)
                Button { Task { await refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(primary)
                        .frame(width: 43, height: 43)
                        .background(surface, in: Circle())
                        .overlay(Circle().strokeBorder(stroke, lineWidth: 1))
                }
                .accessibilityLabel("Refresh Earn")
                .disabled(isLoading)
            }
        }
    }

    private var guestPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Sign in to get started", systemImage: "person.crop.circle")
                .font(.headline)
                .foregroundStyle(primary)
            Text("Keep a paid Plus or Vault subscription active for two months to qualify for LaterBox Earn.")
                .font(.subheadline)
                .foregroundStyle(secondary)
            Button("Sign in") { coordinator.showingAuthSheet = true }
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(Color(hex: "171711"))
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func summary(for value: EarnDashboardDTO) -> some View {
        HStack(spacing: 10) {
            balanceCard("Pending", cents: value.balances.pendingCents, icon: "clock")
            balanceCard("Available", cents: value.balances.availableCents, icon: "wallet.pass")
            balanceCard("Paid", cents: value.balances.paidCents, icon: "checkmark.seal")
        }
    }

    private func balanceCard(_ label: String, cents: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).font(.system(size: 17)).foregroundStyle(secondary)
            Text(currency(cents))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(primary)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(stroke, lineWidth: 1))
    }

    private func eligibilityPanel(for value: EarnDashboardDTO) -> some View {
        let active = value.status == "active"
        let statusText: String = {
            switch value.status {
            case "active": return "Community Referrer"
            case "eligible": return "Activate your referral earnings"
            case "not_launched": return "Your referral code is reserved"
            case "suspended": return "Affiliate account on hold"
            default: return "Your path to earning"
            }
        }()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR STATUS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "566B3E"))
                Spacer()
                Text(value.plan.capitalized)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.7), in: Capsule())
                    .foregroundStyle(Color(hex: "2C3A24"))
            }
            Text(statusText)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
            Text(statusDescription(value))
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "56654F"))
                .fixedSize(horizontal: false, vertical: true)
            if let progress = membershipTenureProgress(value) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("PAID MEMBERSHIP TENURE")
                        Spacer()
                        Text(progress >= 1 ? "2 months complete" : "In progress")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "526C3C"))
                    ProgressView(value: progress)
                        .tint(Color(hex: "55743E"))
                }
                .padding(.top, 5)
            }
            if !active && value.plan != "free" {
                Button {
                    coordinator.showingPlansSheet = true
                } label: {
                    Label("Explore Plus and Vault", systemImage: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(hex: "31502A"))
                }
            }
            if active {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Active affiliate account")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "3C5731"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "E6EDB0"), in: RoundedRectangle(cornerRadius: 21))
    }

    private func membershipTenureProgress(_ value: EarnDashboardDTO) -> Double? {
        guard value.plan != "free",
              let start = value.memberSince,
              let end = value.eligibleAt,
              let startDate = ISO8601DateFormatter().date(from: start),
              let endDate = ISO8601DateFormatter().date(from: end) else { return nil }
        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0 else { return nil }
        return max(0, min(1, Date().timeIntervalSince(startDate) / duration))
    }

    private func statusDescription(_ value: EarnDashboardDTO) -> String {
        switch value.status {
        case "not_launched":
            return "We are finalizing commission rates, payout verification, and the program terms. No new commissions can be earned yet."
        case "eligible":
            return "Connect and verify Whop first. Then confirm your age and accept the terms to activate referrals on Free or paid plans."
        case "active":
            return "Share your code. Eligible recurring payments earn commission after the referred user finishes a free trial and two paid months."
        case "suspended":
            return "Your referral program access is temporarily paused."
        default:
            if value.awaitingReceipts == true {
                return "Your subscription is old enough. We still need to verify your completed paid billing cycles."
            }
            if let date = value.eligibleAt {
                return "Keep your paid subscription active until \(dateLabel(date)) to complete the two-month requirement."
            }
            return "Everyone can refer, including Free accounts. Your referrals qualify after paid subscription verification."
        }
    }

    private func referralPanel(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Your referral link", systemImage: "link")
                .font(.headline)
                .foregroundStyle(primary)
            Text("Share your unique code or link. Commissions start only after referred subscribers complete their trial and two paid months. Disclose that you may earn money.")
                .font(.subheadline)
                .foregroundStyle(secondary)
            Text(value.referralUrl ?? "Link unavailable")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(primary)
                .textSelection(.enabled)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(stroke.opacity(0.25), in: RoundedRectangle(cornerRadius: 11))
            Button {
                guard let url = value.referralUrl else { return }
                UIPasteboard.general.string = url + "\nDisclosure: I may receive a commission if you purchase LaterBox through this link."
                didCopy = true
            } label: {
                Label(didCopy ? "Copied with disclosure" : "Copy referral link", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "171711"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 13))
            }
            HStack(spacing: 12) {
                Text(value.referralCode ?? "")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(primary)
                    .textSelection(.enabled)
                Button("Copy code") {
                    UIPasteboard.general.string = value.referralCode
                    didCopy = true
                }
                Button("Customize") {
                    codeToEdit = value.referralCode ?? ""
                    editingCode = true
                }
                .disabled(updatingCode)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(secondary)
            HStack {
                Text("\(value.referrals) referred accounts")
                Spacer()
                if let bps = value.rateBps {
                    Text("\(bps / 100)% commission")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(secondary)
            Divider()
            HStack(spacing: 10) {
                Image(systemName: value.payoutConnected ? "checkmark.seal.fill" : "creditcard")
                    .foregroundStyle(secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(value.payoutConnected ? "Whop connected" : "Connect your Whop payout account")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primary)
                    Text(value.payoutConnected ? "Verified for earnings transfers" : "Secure connection and verification happen on the LaterBox website.")
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
                Spacer(minLength: 6)
                if !value.payoutConnected {
                    Button("Connect") {
                        if let url = URL(string: "\(LaterBoxAPIService.shared.billingUrl)/earn") {
                            openURL(url)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primary)
                }
            }
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func enrollmentPanel(for value: EarnDashboardDTO) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activate referral earnings")
                .font(.headline)
                .foregroundStyle(primary)
            Text("Connect a verified Whop account, confirm your age, and accept the terms before activating referrals. A paid LaterBox plan is not required.")
                .font(.subheadline)
                .foregroundStyle(secondary)
            if !value.payoutConnected {
                Button("Connect Whop to continue") {
                    if let url = URL(string: "\(LaterBoxAPIService.shared.billingUrl)/earn") { openURL(url) }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(hex: "31502A"))
            } else {
                Label("Whop verified", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            Toggle("I confirm that I am 18 or older", isOn: $confirmsAdult)
                .font(.subheadline)
                .tint(AppTheme.accent)
            Toggle("I agree to the affiliate program terms", isOn: $acceptsTerms)
                .font(.subheadline)
                .tint(AppTheme.accent)
            Button("Read the program terms") {
                if let url = URL(string: "\(LaterBoxAPIService.shared.webUrl)/earn-terms") {
                    openURL(url)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(primary)
            Button {
                Task { await join() }
            } label: {
                HStack(spacing: 8) {
                    if isJoining { ProgressView().tint(.white) }
                    Text(isJoining ? "Activating…" : "Join LaterBox Earn")
                }
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 13))
            }
            .disabled(isJoining || !value.payoutConnected || !confirmsAdult || !acceptsTerms)
            .opacity(isJoining || !value.payoutConnected || !confirmsAdult || !acceptsTerms ? 0.55 : 1)
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
                        .font(.system(size: 26))
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
                .padding(.vertical, 24)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("How Earn works").font(.headline).foregroundStyle(primary)
            processRow("1", title: "Share", detail: "Everyone can share a unique referral code, even on Free.")
            processRow("2", title: "Trial", detail: "New referred subscribers get a free trial when the promotion is active.")
            processRow("3", title: "Qualify", detail: "Referred customers complete two paid months after the trial.")
            processRow("4", title: "Release", detail: "After the hold and refund checks, funds become available.")
            processRow("5", title: "Withdraw", detail: "Whop manages verified payouts and withdrawals.")
            Divider()
            Button {
                if let url = URL(string: "https://whop.com/") { openURL(url) }
            } label: {
                Label("Open Whop for withdrawals", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primary)
            }
            Text("Whop handles bank details, identity checks and withdrawals. LaterBox never asks you for bank credentials.")
                .font(.caption)
                .foregroundStyle(secondary)
        }
        .earnPanel(surface: surface, stroke: stroke)
    }

    private func processRow(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 29, height: 29)
                .background(AppTheme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
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
            .padding(19)
            .background(surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(stroke, lineWidth: 1))
    }
}
private extension View {
    func earnPanel(surface: Color, stroke: Color) -> some View {
        modifier(EarnPanelModifier(surface: surface, stroke: stroke))
    }
}
