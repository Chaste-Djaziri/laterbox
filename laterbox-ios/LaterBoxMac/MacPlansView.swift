// laterbox-ios/LaterBoxMac/MacPlansView.swift
import SwiftUI
import AppKit

private struct MacWhopQuote: Decodable {
    let id: String
    let currency: String
    let renewalPrice: Double
    let interval: String
    let trialDays: Int
    let taxType: String
}
private struct MacWhopCatalog: Decodable {
    let prices: [String: MacWhopQuote]
}
private struct MacBillingEntitlement: Decodable {
    let tier: String
    let provider: String?
    let status: String
    let storagePlanKey: String?
    let storageLimitBytes: Int64?
    let storageUsedBytes: Int64?
    let willCancel: Bool?
    let accessEndsAt: String?
}
private struct MacBillingPortal: Decodable { let url: String }

private struct MacStorageTier: Identifiable {
    let key: String
    let name: String
    let size: String
    let bytes: Int64
    let description: String
    var id: String { key }
}
private let macStorageTiers: [MacStorageTier] = [
    .init(key: "plus50", name: "Plus 50", size: "50 GB", bytes: 50 * 1_073_741_824,
          description: "More space for large documents and creative references."),
    .init(key: "vault", name: "Vault 100", size: "100 GB", bytes: 100 * 1_073_741_824,
          description: "Build your personal collection of documents and media."),
    .init(key: "vault250", name: "Vault 250", size: "250 GB", bytes: 250 * 1_073_741_824,
          description: "For bigger creative and research projects."),
    .init(key: "vault500", name: "Vault 500", size: "500 GB", bytes: 500 * 1_073_741_824,
          description: "Room for an extensive, evolving library."),
    .init(key: "vault1tb", name: "Vault 1 TB", size: "1 TB", bytes: 1024 * 1_073_741_824,
          description: "Archive your files across devices."),
    .init(key: "vault2tb", name: "Vault 2 TB", size: "2 TB", bytes: 2048 * 1_073_741_824,
          description: "Maximum available cloud storage capacity.")
]

struct MacPlansView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    @Environment(\.colorScheme) private var scheme
    @State private var interval = "year"
    @State private var sliderIndex = 1
    @State private var catalog: MacWhopCatalog?
    @State private var entitlement: MacBillingEntitlement?
    @State private var loadingPrices = true
    @State private var loadingAccount = true
    @State private var managing = false
    @State private var priceError: String?
    @State private var accountError: String?
    @State private var manageError: String?

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private let ink = Color(red: 23 / 255, green: 23 / 255, blue: 17 / 255)
    private var dark: Bool { scheme == .dark }
    private var surface: Color { dark ? Color(red: 38 / 255, green: 40 / 255, blue: 43 / 255) : .white }
    private var muted: Color { dark ? .white.opacity(0.62) : .black.opacity(0.58) }
    private var border: Color { dark ? .white.opacity(0.14) : .black.opacity(0.10) }
    private var selectedTier: MacStorageTier { macStorageTiers[sliderIndex] }
    private var paidSubscription: Bool {
        guard let status = entitlement?.status else { return false }
        return entitlement?.provider != nil &&
          ["active", "trialing", "past_due"].contains(status) ||
          (entitlement?.provider != nil && status == "canceled" &&
           (entitlement?.accessEndsAt.flatMap(Self.parseDate).map { $0 > Date() } ?? false))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                VStack(spacing: 9) {
                    Text("STORAGE PLANS")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(ink)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 7)
                        .background(lime, in: Capsule())
                    Text("Keep what matters.\nChoose your space.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Saving links and syncing across devices stays free. Add cloud space when you need it.")
                        .font(.system(size: 13))
                        .foregroundStyle(muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                if let entitlement { currentPlanCard(entitlement) }
                if loadingAccount || loadingPrices {
                    HStack(spacing: 9) {
                        ProgressView().controlSize(.small)
                        Text("Checking your subscription and live prices…")
                            .font(.system(size: 12)).foregroundStyle(muted)
                    }
                }
                if let accountError {
                    errorRow(accountError)
                }
                if let priceError {
                    HStack(spacing: 12) {
                        errorRow(priceError)
                        Spacer()
                        Button("Retry pricing") { Task { await fetchPrices() } }
                            .buttonStyle(.bordered)
                    }
                }

                Picker("Billing period", selection: $interval) {
                    Text("Pay monthly").tag("month")
                    Text("Pay yearly").tag("year")
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                .accessibilityIdentifier("mac.plans.billingPeriod")

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 13) {
                        freeCard
                        plusCard
                        vaultCard
                    }
                    VStack(spacing: 13) {
                        freeCard
                        plusCard
                        vaultCard
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Your library stays yours", systemImage: "checkmark.shield")
                        .font(.system(size: 15, weight: .bold))
                    Text("Every plan includes unlimited links and collections, search, and cross-device sync. Paid plans increase attachment storage. Subscription prices are verified live with Whop and the exact amount, taxes and any eligible trial are confirmed at checkout.")
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 16) {
                        Button("Billing settings on Web") { open("https://laterbox.dev/settings/billing") }
                        Button("Frequently asked questions") { open("https://laterbox.dev/help") }
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(border))
            }
            .padding(24)
            .frame(maxWidth: 1150)
            .frame(maxWidth: .infinity)
        }
        .task {
            async let a: Void = fetchPrices()
            async let b: Void = fetchEntitlement()
            _ = await (a, b)
        }
    }

    private func errorRow(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.system(size: 11))
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func currentPlanCard(_ account: MacBillingEntitlement) -> some View {
        let used = account.storageUsedBytes
        let limit = account.storageLimitBytes
        let fraction = used != nil && limit != nil && limit! > 0 ?
            min(1, Double(used!) / Double(limit!)) : nil
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ink)
                    .frame(width: 38, height: 38)
                    .background(lime, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your current plan")
                        .font(.system(size: 11)).foregroundStyle(muted)
                    Text(currentName(account))
                        .font(.system(size: 15, weight: .bold))
                }
                Spacer()
                if paidSubscription {
                    Button {
                        Task { await openPortal() }
                    } label: {
                        if managing { ProgressView().controlSize(.small) }
                        else { Label("Manage subscription", systemImage: "arrow.up.right.square") }
                    }
                    .buttonStyle(.bordered)
                    .disabled(managing)
                }
            }
            if let used, let limit {
                HStack {
                    Text("\(formatBytes(used)) used")
                    Spacer()
                    Text("\(formatBytes(limit)) total")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(muted)
                if let fraction {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.10))
                            Capsule().fill(dark ? lime : ink)
                                .frame(width: proxy.size.width * fraction)
                        }
                    }
                    .frame(height: 7)
                    .accessibilityLabel("Cloud storage used: \(Int(fraction * 100)) percent")
                }
            } else {
                Text("Cloud storage usage is currently unavailable.")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
            if account.willCancel == true {
                Text("Your subscription is scheduled to end.")
                    .font(.system(size: 11)).foregroundStyle(.orange)
            }
            if let manageError { errorRow(manageError) }
        }
        .padding(17)
        .background(surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(border))
    }

    private func currentName(_ account: MacBillingEntitlement) -> String {
        if let key = account.storagePlanKey {
            let family = key.replacingOccurrences(of: "_month", with: "")
                .replacingOccurrences(of: "_year", with: "")
            if family == "plus" { return "Plus · 10 GB" }
            if let tier = macStorageTiers.first(where: { $0.key == family }) {
                return "\(tier.name) · \(tier.size)"
            }
        }
        return account.tier == "pro" ? "Paid / granted storage" : "Free · 500 MB"
    }

    private var freeCard: some View {
        planCard(name: "Free", subtitle: "Everything you need to keep ideas organized.",
                 icon: "icloud", badge: "Free forever", featured: false) {
            VStack(alignment: .leading, spacing: 11) {
                Text("$0")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("500 MB of cloud storage")
                    .font(.system(size: 12, weight: .bold))
                feature("Cross-device sync")
                feature("Unlimited links & collections")
                feature("Reminders & search")
                feature("Keep your saved library")
                Spacer(minLength: 7)
                Label("Included with every account", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 11)
            }
        }
    }

    private var plusCard: some View {
        planCard(name: "LaterBox Plus", subtitle: "More cloud storage for everyday files.",
                 icon: "bolt.fill", badge: "Most popular", featured: true) {
            VStack(alignment: .leading, spacing: 11) {
                priceView(for: "plus")
                Text("10 GB of cloud storage")
                    .font(.system(size: 12, weight: .bold))
                feature("Everything in Free")
                feature("Store PDFs, images & files")
                feature("Sync your media & references")
                feature("Save full-page content")
                Spacer(minLength: 7)
                purchaseButton(key: "plus")
            }
        }
    }

    private var vaultCard: some View {
        planCard(name: selectedTier.name, subtitle: selectedTier.description,
                 icon: "externaldrive.fill", badge: "Scalable storage", featured: false) {
            VStack(alignment: .leading, spacing: 11) {
                priceView(for: selectedTier.key)
                Text("\(selectedTier.size) of cloud storage")
                    .font(.system(size: 12, weight: .bold))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Adjust storage")
                        Spacer()
                        Text(selectedTier.size).foregroundStyle(dark ? lime : ink)
                    }
                    .font(.system(size: 11, weight: .bold))
                    Slider(value: Binding(
                        get: { Double(sliderIndex) },
                        set: { sliderIndex = Int($0.rounded()) }
                    ), in: 0...Double(macStorageTiers.count - 1), step: 1)
                    .tint(dark ? lime : ink)
                    HStack(spacing: 3) {
                        ForEach(Array(macStorageTiers.enumerated()), id: \.element.id) { index, tier in
                            Button(tier.size) { sliderIndex = index }
                                .font(.system(size: 9, weight: index == sliderIndex ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(index == sliderIndex ? lime : Color.primary.opacity(0.05),
                                            in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(index == sliderIndex ? ink : .primary)
                                .buttonStyle(.plain)
                        }
                    }
                }
                feature("Everything in Plus")
                feature("Large-file and media storage")
                Spacer(minLength: 7)
                purchaseButton(key: selectedTier.key)
            }
        }
    }

    private func planCard<Content: View>(name: String, subtitle: String, icon: String,
                                           badge: String, featured: Bool,
                                           @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(featured ? ink : (dark ? Color.white : ink))
                    .frame(width: 39, height: 39)
                    .background(featured ? lime : lime.opacity(dark ? 0.14 : 0.5),
                                in: RoundedRectangle(cornerRadius: 12))
                Spacer()
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(featured ? lime : Color.primary.opacity(0.07), in: Capsule())
                    .foregroundStyle(featured ? ink : .primary)
            }
            Text(name)
                .font(.system(size: 19, weight: .bold))
            Text(subtitle)
                .font(.system(size: 12)).foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 34, alignment: .topLeading)
            Divider()
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 450, maxHeight: .infinity, alignment: .topLeading)
        .background(surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(featured ? lime.opacity(0.65) : border))
    }

    private func feature(_ value: String) -> some View {
        Label(value, systemImage: "checkmark")
            .font(.system(size: 11, weight: .medium))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func priceView(for key: String) -> some View {
        let quote = catalog?.prices["\(key)_\(interval)"]
        return VStack(alignment: .leading, spacing: 5) {
            if let quote {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(quote.renewalPrice.formatted(.currency(code: quote.currency)))
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("/ \(interval == "month" ? "month" : "year")")
                        .font(.system(size: 10))
                        .foregroundStyle(muted)
                }
                if interval == "year",
                   let monthly = catalog?.prices["\(key)_month"],
                   monthly.currency == quote.currency, monthly.renewalPrice > 0 {
                    let discount = max(0, (1 - quote.renewalPrice / (monthly.renewalPrice * 12)) * 100)
                    Text("Save \(Int(discount.rounded()))% compared with monthly")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(dark ? lime : Color(red: 0.28, green: 0.42, blue: 0.20))
                } else {
                    Text("Billed \(interval == "month" ? "monthly" : "annually") · Cancel anytime")
                        .font(.system(size: 10)).foregroundStyle(muted)
                }
            } else if loadingPrices {
                ProgressView().controlSize(.small).frame(height: 39)
            } else {
                Text("Live price unavailable")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(height: 39)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
    }

    @ViewBuilder
    private func purchaseButton(key: String) -> some View {
        if paidSubscription {
            Button("Manage your plan") { Task { await openPortal() } }
                .buttonStyle(.borderedProminent)
                .disabled(managing)
        } else {
            Button {
                openCheckout(key: key)
            } label: {
                Label("Choose \(key == "plus" ? "Plus" : selectedTier.name)", systemImage: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(lime)
            .disabled(loadingAccount || accountError != nil ||
                      catalog?.prices["\(key)_\(interval)"] == nil)
            .help("Continue to the secure LaterBox Web checkout")
        }
    }

    private func openCheckout(key: String) {
        let plan = key
        let path = "/checkout?plan=\(plan)&interval=\(interval)"
        var url = URLComponents(string: "https://laterbox.dev/login")!
        url.queryItems = [URLQueryItem(name: "next", value: path)]
        if let destination = url.url { NSWorkspace.shared.open(destination) }
    }

    private func open(_ raw: String) {
        if let url = URL(string: raw) { NSWorkspace.shared.open(url) }
    }

    private func fetchPrices() async {
        loadingPrices = true
        priceError = nil
        defer { loadingPrices = false }
        do {
            var request = URLRequest(url: URL(string: "https://laterbox.dev/api/billing/prices")!)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 25
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            catalog = try JSONDecoder().decode(MacWhopCatalog.self, from: data)
        } catch {
            priceError = "Live Whop prices could not be verified. Try again before purchasing."
        }
    }

    private func fetchEntitlement() async {
        loadingAccount = true
        accountError = nil
        defer { loadingAccount = false }
        do {
            let data = try await cloud.billingAPI("/entitlement")
            entitlement = try JSONDecoder().decode(MacBillingEntitlement.self, from: data)
        } catch {
            accountError = "Subscription status is unavailable: \(error.localizedDescription)"
        }
    }

    private func openPortal() async {
        guard !managing else { return }
        managing = true
        manageError = nil
        defer { managing = false }
        do {
            let data = try await cloud.billingAPI("/portal", method: "POST",
                                                  body: ["action": "manage"])
            let portal = try JSONDecoder().decode(MacBillingPortal.self, from: data)
            guard let url = URL(string: portal.url), url.scheme == "https",
                  let host = url.host?.lowercased(),
                  (host == "whop.com" || host.hasSuffix(".whop.com") ||
                   host == "paddle.com" || host.hasSuffix(".paddle.com")) else {
                throw URLError(.badURL)
            }
            NSWorkspace.shared.open(url)
        } catch {
            manageError = error.localizedDescription
        }
    }

    private func formatBytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    private static func parseDate(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value) ??
        ISO8601DateFormatter().date(from: value.replacingOccurrences(of: ".000Z", with: "Z"))
    }
}
