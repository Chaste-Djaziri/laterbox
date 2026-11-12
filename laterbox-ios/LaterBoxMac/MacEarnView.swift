// laterbox-ios/LaterBoxMac/MacEarnView.swift
import SwiftUI
import AppKit

// All figures are returned by LaterBox's authenticated Earn API, which owns
// Whop reconciliation and qualification; the Mac never estimates commissions.
private struct MacEarnBalance: Decodable {
    let pendingCents: Int
    let availableCents: Int
    let processingCents: Int
    let paidCents: Int
    let reversedCents: Int
}
private struct MacEarnProgress: Decodable, Identifiable {
    let id: String
    let plan: String
    let status: String
    let referredAt: String
    let trialEndsAt: String?
    let qualifiedAt: String?
    let nextStep: String
}
private struct MacEarnCommission: Decodable, Identifiable {
    let id: String
    let amountCents: Int
    let status: String
    let createdAt: String
    let holdUntil: String
}
private struct MacEarnPayout: Decodable, Identifiable {
    let id: String
    let amountCents: Int
    let status: String
    let createdAt: String
    let paidAt: String?
}
private struct MacEarnState: Decodable {
    let programEnabled: Bool
    let payoutsEnabled: Bool
    let trialEnabled: Bool
    let trialDays: Int
    let eligible: Bool
    let plan: String
    let status: String
    let rateBps: Int?
    let referralCode: String?
    let referralUrl: String?
    let payoutConnected: Bool
    let balances: MacEarnBalance
    let referrals: Int
    let referredProgress: [MacEarnProgress]
    let commissions: [MacEarnCommission]
    let payouts: [MacEarnPayout]
}

struct MacEarnView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    @Environment(\.colorScheme) private var theme
    @State private var state: MacEarnState?
    @State private var loading = false
    @State private var working = false
    @State private var error: String?
    @State private var copied: String?
    @State private var editingCode = false
    @State private var customCode = ""
    @State private var adult = false
    @State private var terms = false

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private var dark: Bool { theme == .dark }
    private var panel: Color { dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white }
    private var muted: Color { dark ? Color.white.opacity(0.64) : Color.black.opacity(0.56) }
    private var line: Color { dark ? Color.white.opacity(0.12) : Color.black.opacity(0.09) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Share Laterbox. Earn together.")
                            .font(.system(size: 24, weight: .bold))
                        Text("Your referrals, qualified rewards and Whop payout activity in one place.")
                            .font(.system(size: 12)).foregroundStyle(muted)
                    }
                    Spacer()
                    Button {
                        Task { await load() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .disabled(loading || working)
                }

                if loading && state == nil {
                    ProgressView("Loading your Earn account…")
                        .frame(maxWidth: .infinity, minHeight: 140)
                } else if let state {
                    if !state.payoutConnected { connectBanner }
                    balanceCards(state.balances)
                    if state.payoutConnected, let code = state.referralCode,
                       state.status != "suspended" {
                        referralCard(state, code: code)
                    }
                    if state.status == "eligible" { enrollmentCard }
                    if state.status == "active" { accountCard(state) }
                    activityCard(state)
                    howItWorks(state)
                } else {
                    VStack(spacing: 13) {
                        Image(systemName: "wifi.exclamationmark").font(.system(size: 26))
                        Text("Earn is unavailable").font(.system(size: 15, weight: .bold))
                        Button("Retry") { Task { await load() } }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .task { await load() }
    }

    private var connectBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STEP 1 · REQUIRED")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1)
            Text("Connect your Whop account to unlock referrals")
                .font(.system(size: 21, weight: .bold))
            Text("Verify your Whop identity on Laterbox Web. Free accounts can participate; joining also requires adult confirmation and acceptance of the affiliate terms.")
                .font(.system(size: 13))
                .lineSpacing(4)
            Button {
                openWebEarn()
            } label: {
                Label("Connect Whop on Web", systemImage: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            Text("Verification uses browser OAuth; the Mac app does not handle your Whop credentials.")
                .font(.system(size: 11))
        }
        .foregroundStyle(Color.black.opacity(0.83))
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lime, in: RoundedRectangle(cornerRadius: 22))
    }

    private func balanceCards(_ value: MacEarnBalance) -> some View {
        HStack(spacing: 12) {
            metric("Pending", cents: value.pendingCents, icon: "clock",
                   detail: "Awaiting verification and hold")
            metric("Available", cents: value.availableCents, icon: "wallet.pass",
                   detail: "Eligible for Whop transfer")
            metric("Paid", cents: value.paidCents, icon: "checkmark.circle",
                   detail: "Transferred and confirmed")
        }
    }

    private func metric(_ title: String, cents: Int, icon: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.system(size: 12, weight: .semibold))
                Spacer()
                Image(systemName: icon)
            }
            .foregroundStyle(muted)
            Text(money(cents))
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(muted)
        }
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 135, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(line))
    }

    private func referralCard(_ value: MacEarnState, code: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your referral link and code", systemImage: "gift")
                .font(.system(size: 16, weight: .bold))
            Text(value.status == "active" && value.programEnabled
                 ? "Share this link and disclose your affiliate relationship."
                 : "Your code is reserved. Attribution and rewards start only when the program and your enrollment are active.")
                .font(.system(size: 12)).foregroundStyle(muted)
            if let link = value.referralUrl, !link.isEmpty {
                HStack(spacing: 8) {
                    Text(link)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        copy(link + "\nI may earn a commission if you buy through my link.", type: "link")
                    } label: {
                        Label(copied == "link" ? "Copied" : "Copy link",
                              systemImage: copied == "link" ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black)
                            .padding(11)
                            .background(lime, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(lime.opacity(dark ? 0.08 : 0.25),
                            in: RoundedRectangle(cornerRadius: 12))
            }
            HStack(spacing: 16) {
                Text("Code: \(code)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .textSelection(.enabled)
                Button(copied == "code" ? "Copied" : "Copy code") {
                    copy(code, type: "code")
                }
                Button(editingCode ? "Cancel" : "Customize") {
                    editingCode.toggle()
                    customCode = code
                }
                Spacer()
                Text("\(value.referrals) referred accounts")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
            .font(.system(size: 12, weight: .semibold))
            .buttonStyle(.plain)
            if editingCode {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Choose your unique referral code")
                        .font(.system(size: 12, weight: .bold))
                    HStack(spacing: 9) {
                        TextField("Referral code", text: $customCode)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                            .onChange(of: customCode) { _, next in
                                customCode = String(next.lowercased().prefix(32))
                            }
                        Button(working ? "Checking…" : "Save code") {
                            Task { await saveCode() }
                        }
                        .disabled(working || customCode.isEmpty)
                    }
                    Text("8–32 lowercase letters, numbers, underscores or hyphens. Reserved and existing codes are unavailable. Changes are limited to once every 30 days.")
                        .font(.system(size: 11)).foregroundStyle(muted)
                }
                .padding(14)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            }
            if value.programEnabled && value.status == "active", let bps = value.rateBps {
                Text("Introductory commission: \(Double(bps) / 100, specifier: "%.1f")% of eligible net renewal revenue. Actual earnings are subject to qualification and terms.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(line))
    }

    private var enrollmentCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Connect Whop and activate Earn")
                .font(.system(size: 17, weight: .bold))
            Text("Participation is available to Free and paid accounts. Connect Whop, confirm your age and accept the Earn terms.")
                .font(.system(size: 12)).foregroundStyle(muted)
            Toggle("I confirm I am at least 18 years old.", isOn: $adult)
                .toggleStyle(.checkbox)
            HStack(spacing: 10) {
                Toggle("I accept the affiliate program terms.", isOn: $terms)
                    .toggleStyle(.checkbox)
                Button("Read terms") {
                    NSWorkspace.shared.open(URL(string: "https://laterbox.dev/earn-terms")!)
                }
                .buttonStyle(.link)
            }
            Button(working ? "Joining…" : "Join Earn") {
                Task { await enroll() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!adult || !terms || working || state?.payoutConnected != true)
        }
        .font(.system(size: 12))
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 19))
    }

    private func accountCard(_ value: MacEarnState) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(value.payoutConnected ? "Whop account verified" : "Connect Whop for payouts")
                    .font(.system(size: 15, weight: .bold))
                Text("Whop handles identity checks, withdrawal methods, and transfers. Laterbox never collects banking credentials.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
            Spacer()
            if value.payoutConnected {
                Text("Connected")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(10)
                    .background(lime, in: Capsule())
            } else {
                Button("Connect Whop") { openWebEarn() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 19))
    }

    private func activityCard(_ value: MacEarnState) -> some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(alignment: .leading, spacing: 13) {
                Text("Referral progress").font(.system(size: 16, weight: .bold))
                if value.referredProgress.isEmpty {
                    Text("No tracked referrals yet. Progress appears after a qualified checkout.")
                        .font(.system(size: 12)).foregroundStyle(muted)
                } else {
                    ForEach(value.referredProgress) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.plan.replacingOccurrences(of: "_", with: " ").uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                Text(entry.nextStep + " · " + niceDate(entry.referredAt))
                                    .font(.system(size: 11)).foregroundStyle(muted)
                            }
                            Spacer()
                            Text(entry.status.capitalized).font(.system(size: 11, weight: .semibold))
                        }
                        Divider()
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(21)
            .background(panel, in: RoundedRectangle(cornerRadius: 19))

            VStack(alignment: .leading, spacing: 13) {
                Text("Earnings and payouts").font(.system(size: 16, weight: .bold))
                if value.commissions.isEmpty && value.payouts.isEmpty {
                    Label("Your first qualified commission will appear here.", systemImage: "dollarsign.circle")
                        .font(.system(size: 12)).foregroundStyle(muted)
                }
                ForEach(value.commissions) { c in
                    activityRow("Recurring commission", subtitle: c.status + " · " + niceDate(c.createdAt),
                                amount: c.amountCents)
                }
                ForEach(value.payouts) { p in
                    activityRow("Whop transfer", subtitle: p.status + " · " + niceDate(p.createdAt),
                                amount: p.amountCents)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(21)
            .background(panel, in: RoundedRectangle(cornerRadius: 19))
        }
    }

    private func activityRow(_ title: String, subtitle: String, amount: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(muted)
            }
            Spacer()
            Text(money(amount)).font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) { line.frame(height: 1) }
    }

    private func howItWorks(_ value: MacEarnState) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("How it works").font(.system(size: 16, weight: .bold))
            HStack(alignment: .top, spacing: 13) {
                step("1", "Connect", "Verify Whop, then share your unique referral link.")
                step("2", "Trial", "A new subscriber receives a free month only on a verified trial offer.")
                step("3", "Qualify", "They must remain subscribed through two successful paid billing periods.")
                step("4", "Earn", "Eligible renewals accrue commission. Whop handles verified payouts.")
            }
            Divider()
            HStack {
                Label("Refunds do not qualify. Terms and regional eligibility apply.",
                      systemImage: "checkmark.shield")
                    .font(.system(size: 11)).foregroundStyle(muted)
                Spacer()
                Button("Manage Whop withdrawals") {
                    NSWorkspace.shared.open(URL(string: "https://whop.com/")!)
                }
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.link)
            }
            if !value.programEnabled {
                Text("Earn referrals are not currently active. Codes and dashboard figures remain visible, but new attribution and payouts depend on program activation.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
        }
        .padding(22)
        .background(panel, in: RoundedRectangle(cornerRadius: 19))
    }

    private func step(_ number: String, _ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 28, height: 28)
                .background(lime, in: Circle())
            Text(title).font(.system(size: 12, weight: .bold))
            Text(description)
                .font(.system(size: 11)).foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func load() async {
        guard !loading || state == nil else { return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            let data = try await cloud.earnAPI()
            state = try JSONDecoder().decode(MacEarnState.self, from: data)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveCode() async {
        guard !working else { return }
        working = true
        defer { working = false }
        do {
            _ = try await cloud.earnAPI("/code", method: "PATCH", body: ["code": customCode])
            editingCode = false
            await load()
        } catch { self.error = error.localizedDescription }
    }

    private func enroll() async {
        guard !working && adult && terms else { return }
        working = true
        defer { working = false }
        do {
            _ = try await cloud.earnAPI(method: "POST", body: ["adult": true, "acceptedTerms": true])
            await load()
        } catch { self.error = error.localizedDescription }
    }

    private func copy(_ value: String, type: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copied = type
    }

    private func openWebEarn() {
        NSWorkspace.shared.open(URL(string: "https://laterbox.dev/earn")!)
    }

    private func money(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "USD"))
    }

    private func niceDate(_ value: String) -> String {
        let date = ISO8601DateFormatter().date(from: value)
            ?? ISO8601DateFormatter().date(from: value.replacingOccurrences(of: ".000Z", with: "Z"))
        return date?.formatted(date: .abbreviated, time: .omitted) ?? value
    }
}
