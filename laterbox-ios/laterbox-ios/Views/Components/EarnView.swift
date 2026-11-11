// laterbox-ios/laterbox-ios/Views/Components/EarnView.swift
import SwiftUI
import UIKit

/// Native Earn dashboard with streamlined metrics, 1-tap copy referral tools,
/// and dedicated sub-pages for Earnings Activity, Payout History, and Program Rules.
struct EarnView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @StateObject private var coordinator = SyncCoordinator.shared
    @State private var dashboard: EarnDashboardDTO?
    @State private var isLoading = false
    @State private var isJoining = false
    @State private var confirmsAdult = false
    @State private var acceptsTerms = false
    @State private var copiedToastMessage: String?
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
            ZStack(alignment: .top) {
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
                            subpagesNavigation(for: dashboard)
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

                if let message = copiedToastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "48613D"))
                        Text(message)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "171711"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "E6EDB0"), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color(hex: "526741").opacity(0.3), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Earn")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(primary)
            Spacer()
            Button {
                Task { await refresh() }
            } label: {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(primary)
                        .frame(width: 36, height: 36)
                        .background(surface, in: Circle())
                        .overlay(Circle().strokeBorder(stroke, lineWidth: 1))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reload Earn")
            .disabled(isLoading)
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
                Image(systemName: "gift.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "6B8951"))
                Text("Your referral link and code")
                    .font(.headline)
                    .foregroundStyle(primary)
                Spacer()
                Text("\(value.referrals) referred")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "597442"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "597442").opacity(0.12), in: Capsule())
            }

            if let url = value.referralUrl {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        copyToClipboard(url, message: "Copied link to clipboard")
                    } label: {
                        HStack {
                            Text(url)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundStyle(secondary)
                        }
                        .padding(12)
                        .background(stroke.opacity(0.25), in: RoundedRectangle(cornerRadius: 11))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Button {
                            copyToClipboard(url, message: "Copied link to clipboard")
                        } label: {
                            Label("Copy link", systemImage: "doc.on.doc")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: "171711"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 11))
                        }

                        if let shareUrl = URL(string: url) {
                            ShareLink(item: shareUrl, message: Text("Sign up for LaterBox with my referral link:")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(primary)
                                    .frame(width: 88, height: 42)
                                    .background(surface, in: RoundedRectangle(cornerRadius: 11))
                                    .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(stroke, lineWidth: 1))
                            }
                        }
                    }
                }
            }

            if let code = value.referralCode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            copyToClipboard(code, message: "Copied code to clipboard")
                        } label: {
                            HStack(spacing: 6) {
                                Text("Code:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(secondary)
                                Text(code)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(primary)
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundStyle(secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(stroke.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button("Customize") {
                            codeToEdit = code
                            editingCode = true
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "597442"))

                        if let url = value.referralUrl {
                            Button("Copy all") {
                                let bundle = "Invite to LaterBox: \(url) (Code: \(code))"
                                copyToClipboard(bundle, message: "Copied referral pack")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "597442"))
                        }
                    }
                }
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

    private func subpagesNavigation(for value: EarnDashboardDTO) -> some View {
        VStack(spacing: 10) {
            NavigationLink {
                EarnCommissionsDetailView(dashboard: value)
            } label: {
                subpageRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Earnings Activity",
                    subtitle: value.commissions.isEmpty
                        ? "No commissions recorded yet"
                        : "\(value.commissions.count) record\(value.commissions.count == 1 ? "" : "s") · \(currency(value.balances.availableCents + value.balances.paidCents)) earned",
                    badge: "\(value.commissions.count)"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                EarnPayoutsDetailView(dashboard: value)
            } label: {
                subpageRow(
                    icon: "wallet.pass",
                    title: "Payout History",
                    subtitle: value.payouts.isEmpty
                        ? "No transfers yet"
                        : "\(value.payouts.count) transfer\(value.payouts.count == 1 ? "" : "s") via Whop",
                    badge: value.payoutConnected ? "Whop verified" : "Whop required"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                EarnGuideDetailView(dashboard: value)
            } label: {
                subpageRow(
                    icon: "book.closed",
                    title: "How It Works & Rules",
                    subtitle: "4-step qualification, hold policies & commission tiers",
                    badge: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func subpageRow(icon: String, title: String, subtitle: String, badge: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "597442"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "597442").opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(stroke.opacity(0.3), in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(secondary.opacity(0.6))
        }
        .padding(14)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(stroke, lineWidth: 1))
    }

    private func copyToClipboard(_ text: String, message: String) {
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedToastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                if copiedToastMessage == message {
                    copiedToastMessage = nil
                }
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
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                return
            }
            if case CloudSyncError.unauthorized = error,
               await coordinator.refreshAuthSession(),
               let newToken = coordinator.authToken {
                do {
                    dashboard = try await LaterBoxAPIService.shared.fetchEarnDashboard(token: newToken)
                } catch {
                    if !(Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled) {
                        errorMessage = error.localizedDescription
                    }
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
}

// MARK: - Subpage 1: Earnings Activity
struct EarnCommissionsDetailView: View {
    let dashboard: EarnDashboardDTO
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFilter: String = "all"
    @State private var toastMessage: String?

    private var primary: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { colorScheme == .dark ? Color(hex: "292D29") : .white }
    private var stroke: Color { InboxAppearance.border(for: colorScheme) }

    private var filteredCommissions: [EarnCommissionDTO] {
        switch selectedFilter {
        case "pending":
            return dashboard.commissions.filter { $0.status.lowercased() == "pending" }
        case "available":
            return dashboard.commissions.filter { $0.status.lowercased() == "available" }
        case "paid":
            return dashboard.commissions.filter { $0.status.lowercased() == "paid" }
        default:
            return dashboard.commissions
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Total Commissions")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(secondary)
                    let totalCents = dashboard.commissions.reduce(0) { $0 + $1.amountCents }
                    Text(currency(totalCents))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                    HStack(spacing: 8) {
                        Label("\(dashboard.commissions.count) total records", systemImage: "tray.full")
                            .font(.caption)
                            .foregroundStyle(secondary)
                        Text("·")
                            .foregroundStyle(secondary)
                        Text("Hold period: 30 days")
                            .font(.caption)
                            .foregroundStyle(secondary)
                    }
                }
                .earnPanel(surface: surface, stroke: stroke)

                Picker("Filter", selection: $selectedFilter) {
                    Text("All (\(dashboard.commissions.count))").tag("all")
                    Text("Pending").tag("pending")
                    Text("Available").tag("available")
                    Text("Paid").tag("paid")
                }
                .pickerStyle(.segmented)

                if filteredCommissions.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "gift")
                            .font(.system(size: 28))
                            .foregroundStyle(secondary)
                        Text("No commissions in this view")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primary)
                        Text("Commissions accrue as referred subscribers complete paid renewal periods.")
                            .font(.caption)
                            .foregroundStyle(secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .earnPanel(surface: surface, stroke: stroke)
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredCommissions, id: \.id) { item in
                            commissionCard(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(InboxGrainBackground().ignoresSafeArea())
        .navigationTitle("Earnings Activity")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let toastMessage {
                toastPill(toastMessage)
            }
        }
    }

    private func commissionCard(_ item: EarnCommissionDTO) -> some View {
        Button {
            copy(item.id, label: "Copied commission ID")
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    statusPill(item.status)
                    Spacer()
                    Text(currency(item.amountCents))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Created \(dateLabel(item.createdAt))")
                            .font(.caption)
                            .foregroundStyle(secondary)
                        if !item.holdUntil.isEmpty {
                            Text("Hold until \(dateLabel(item.holdUntil))")
                                .font(.system(size: 11))
                                .foregroundStyle(secondary.opacity(0.8))
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(item.id.prefix(8) + "…")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(secondary)
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(secondary)
                    }
                }
            }
            .earnPanel(surface: surface, stroke: stroke)
        }
        .buttonStyle(.plain)
    }

    private func statusPill(_ status: String) -> some View {
        let isSuccess = status.lowercased() == "available" || status.lowercased() == "paid"
        let isPending = status.lowercased() == "pending"
        return Text(status.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isSuccess ? Color(hex: "48613D") : (isPending ? Color(hex: "8A6818") : secondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                (isSuccess ? Color(hex: "48613D").opacity(0.12) : (isPending ? Color(hex: "8A6818").opacity(0.12) : stroke.opacity(0.3))),
                in: Capsule()
            )
    }

    private func copy(_ text: String, label: String) {
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toastMessage = label
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                if toastMessage == label { toastMessage = nil }
            }
        }
    }

    private func toastPill(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "48613D"))
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "E6EDB0"), in: Capsule())
        .overlay(Capsule().strokeBorder(Color(hex: "526741").opacity(0.3), lineWidth: 1))
        .padding(.top, 8)
    }

    private func currency(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "USD"))
    }
    private func dateLabel(_ raw: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: raw) else { return raw }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Subpage 2: Payout History
struct EarnPayoutsDetailView: View {
    let dashboard: EarnDashboardDTO
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var toastMessage: String?

    private var primary: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { colorScheme == .dark ? Color(hex: "292D29") : .white }
    private var stroke: Color { InboxAppearance.border(for: colorScheme) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: dashboard.payoutConnected ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(dashboard.payoutConnected ? Color(hex: "48613D") : Color(hex: "8A6818"))
                        Text(dashboard.payoutConnected ? "Whop account verified" : "Whop connection required")
                            .font(.headline)
                            .foregroundStyle(primary)
                    }
                    Text(dashboard.payoutConnected
                        ? "Whop manages payouts, verified tax documentation, and automated bank transfers for LaterBox."
                        : "Connect and verify your Whop account to enable automated payouts and balance withdrawals.")
                        .font(.subheadline)
                        .foregroundStyle(secondary)

                    Button {
                        if let url = URL(string: "https://whop.com/") { openURL(url) }
                    } label: {
                        Label("Open Whop portal", systemImage: "arrow.up.right.square")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(primary)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(stroke.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .earnPanel(surface: surface, stroke: stroke)

                Text("Transfer records")
                    .font(.headline)
                    .foregroundStyle(primary)

                if dashboard.payouts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "wallet.pass")
                            .font(.system(size: 28))
                            .foregroundStyle(secondary)
                        Text("No payouts transferred yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primary)
                        Text("Once approved commissions transition to Available, transfers are processed directly to your Whop account.")
                            .font(.caption)
                            .foregroundStyle(secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .earnPanel(surface: surface, stroke: stroke)
                } else {
                    VStack(spacing: 10) {
                        ForEach(dashboard.payouts, id: \.id) { item in
                            payoutCard(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(InboxGrainBackground().ignoresSafeArea())
        .navigationTitle("Payout History")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let toastMessage {
                toastPill(toastMessage)
            }
        }
    }

    private func payoutCard(_ item: EarnPayoutDTO) -> some View {
        Button {
            copy(item.id, label: "Copied transfer ID")
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.status.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "48613D"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "48613D").opacity(0.12), in: Capsule())
                    Spacer()
                    Text(currency(item.amountCents))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                }
                HStack {
                    Text(dateLabel(item.createdAt))
                        .font(.caption)
                        .foregroundStyle(secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(item.id.prefix(8) + "…")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(secondary)
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(secondary)
                    }
                }
            }
            .earnPanel(surface: surface, stroke: stroke)
        }
        .buttonStyle(.plain)
    }

    private func copy(_ text: String, label: String) {
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toastMessage = label
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                if toastMessage == label { toastMessage = nil }
            }
        }
    }

    private func toastPill(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "48613D"))
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "171711"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "E6EDB0"), in: Capsule())
        .overlay(Capsule().strokeBorder(Color(hex: "526741").opacity(0.3), lineWidth: 1))
        .padding(.top, 8)
    }

    private func currency(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: "USD"))
    }
    private func dateLabel(_ raw: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: raw) else { return raw }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Subpage 3: How It Works & Program Rules
struct EarnGuideDetailView: View {
    let dashboard: EarnDashboardDTO
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private var primary: Color { InboxAppearance.textPrimary(for: colorScheme) }
    private var secondary: Color { InboxAppearance.textSecondary(for: colorScheme) }
    private var surface: Color { colorScheme == .dark ? Color(hex: "292D29") : .white }
    private var stroke: Color { InboxAppearance.border(for: colorScheme) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How Earn Works")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primary)
                    Text("Earn recurring commissions by inviting new subscribers to LaterBox. Everything is automated through verified Whop billing.")
                        .font(.subheadline)
                        .foregroundStyle(secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Qualification steps")
                        .font(.headline)
                        .foregroundStyle(primary)

                    stepCard("1", title: "Connect & Share", detail: "Verify your Whop identity to unlock your unique referral link and custom code. Anyone on a Free or Paid LaterBox plan can participate.")
                    stepCard("2", title: "Free Trial Promotion", detail: "Referred subscribers start with an introductory free trial when promotional offers are active in their region.")
                    stepCard("3", title: "Subscription Qualification", detail: "The referee must remain active and successfully complete two paid consecutive billing periods following any promotional trial.")
                    stepCard("4", title: "Commission Accrual", detail: "Eligible renewals accrue commission. Following standard 30-day anti-fraud holds, balances transition to Available for Whop transfer.")
                }
                .earnPanel(surface: surface, stroke: stroke)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Commission Structure")
                        .font(.headline)
                        .foregroundStyle(primary)
                    let ratePercent = dashboard.rateBps.map { Double($0) / 100.0 } ?? 50.0
                    HStack(spacing: 12) {
                        Text("\(String(format: "%.0f", ratePercent))%")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: "48613D"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Introductory Commission Rate")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primary)
                            Text("Accrues on eligible net renewal revenue from qualified referred accounts.")
                                .font(.caption)
                                .foregroundStyle(secondary)
                        }
                    }
                }
                .earnPanel(surface: surface, stroke: stroke)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Program Rules & Policies")
                        .font(.headline)
                        .foregroundStyle(primary)

                    policyRow(icon: "shield.checkmark", title: "Refunds & Reversals", text: "Refunded or chargeback transactions do not qualify for commission. Any associated pending amounts are reversed.")
                    policyRow(icon: "clock.arrow.circlepath", title: "30-Day Hold Period", text: "All accrued commissions remain in Pending status for 30 days to ensure refund and billing clearance.")
                    policyRow(icon: "banknote", title: "Automated Whop Withdrawals", text: "LaterBox never handles or stores your bank credentials. All identity checks, bank transfers, and tax forms are processed by Whop.")
                }
                .earnPanel(surface: surface, stroke: stroke)

                Button {
                    if let url = URL(string: "https://whop.com/") { openURL(url) }
                } label: {
                    Label("Manage Whop withdrawals", systemImage: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(InboxGrainBackground().ignoresSafeArea())
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepCard(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "171711"))
                .frame(width: 28, height: 28)
                .background(AppTheme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(secondary)
                    .lineSpacing(2)
            }
        }
    }

    private func policyRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "597442"))
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primary)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(secondary)
                    .lineSpacing(2)
            }
        }
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
