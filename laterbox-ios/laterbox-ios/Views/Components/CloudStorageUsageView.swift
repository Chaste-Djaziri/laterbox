// laterbox-ios/laterbox-ios/Views/Components/CloudStorageUsageView.swift
import SwiftUI

/// Same server-side cloud storage thresholds and colors as the web sidebar.
/// Do not substitute LocalStorageManager values: they measure phone disk usage.
struct CloudStorageQuota {
    enum Level {
        case unknown, normal, warning, critical, full

        var ringColor: Color {
            switch self {
            case .unknown: Color(hex: "ACB4A2")
            case .normal: Color(hex: "8AA666")
            case .warning: Color(hex: "D49431")
            case .critical: Color(hex: "CC673E")
            case .full: Color(hex: "BC3E3E")
            }
        }

        var title: String {
            switch self {
            case .unknown: "Storage usage unavailable"
            case .normal: "Cloud storage"
            case .warning: "Storage almost full"
            case .critical: "Storage nearly full"
            case .full: "Storage full"
            }
        }

        var message: String {
            switch self {
            case .unknown: "We could not retrieve your current cloud storage usage."
            case .normal: "Your cloud storage is within its plan limit."
            case .warning: "You have used over 80% of your cloud space. Consider freeing space or upgrading."
            case .critical: "Less than 5% of your cloud space remains. Upgrade or clear unused files soon."
            case .full: "Your storage limit has been reached. Upgrade your plan or remove stored files to free up space."
            }
        }

        var isAlert: Bool {
            switch self {
            case .warning, .critical, .full: true
            case .unknown, .normal: false
            }
        }
    }

    let usedBytes: Int64?
    let limitBytes: Int64?

    var percent: Double? {
        guard let usedBytes, let limitBytes, usedBytes >= 0, limitBytes > 0 else {
            return nil
        }
        return (Double(usedBytes) / Double(limitBytes)) * 100
    }

    var ringFraction: CGFloat? {
        guard let percent else { return nil }
        return CGFloat(min(1, max(0, percent / 100)))
    }

    var level: Level {
        guard let percent else { return .unknown }
        if percent >= 100 { return .full }
        if percent >= 95 { return .critical }
        if percent >= 80 { return .warning }
        return .normal
    }

    var usedLabel: String {
        guard percent != nil, let usedBytes else { return "Usage unavailable" }
        return Self.formatBytes(usedBytes)
    }

    var limitLabel: String {
        guard let limitBytes, limitBytes > 0 else { return "Limit unavailable" }
        return Self.formatBytes(limitBytes)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return "Unavailable" }
        if bytes == 0 { return "0 MB" }
        if bytes < 1_000_000 { return "\(Int(ceil(Double(bytes) / 1_000))) KB" }
        if bytes < 1_000_000_000 {
            return "\(Double((Double(bytes) / 1_000_000 * 10).rounded()) / 10) MB"
        }
        return "\(Double((Double(bytes) / 1_000_000_000 * 100).rounded()) / 100) GB"
    }

    static func from(_ entitlement: AccountBillingEntitlement?) -> Self {
        Self(usedBytes: entitlement?.storageUsedBytes, limitBytes: entitlement?.storageLimitBytes)
    }
}

/// A 48-point quota ring with the same design language as the web sidebar.
struct CloudStorageUsageRing: View {
    @Environment(\.colorScheme) private var colorScheme
    let quota: CloudStorageQuota
    var isSignedIn: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.18) : Color(hex: "E1E5D9"),
                    lineWidth: 3.5
                )
            if isSignedIn, let fraction = quota.ringFraction {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        quota.level.ringColor,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: fraction)
            }

            Image(systemName: "internaldrive")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(
                    quota.level.isAlert && isSignedIn
                        ? Color(hex: "A45A30")
                        : colorScheme == .dark ? Color.white.opacity(0.8) : Color(hex: "737D68")
                )

            if quota.level.isAlert && isSignedIn {
                Text("!")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 15, height: 15)
                    .background(quota.level.ringColor, in: Circle())
                    .overlay(Circle().strokeBorder(
                        colorScheme == .dark ? Color.black : Color.white, lineWidth: 2
                    ))
                    .offset(x: 20, y: -19)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 41, height: 41)
        .frame(width: 48, height: 48)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}

struct CloudStorageUsageDetails: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var coordinator = SyncCoordinator.shared

    private var isSignedIn: Bool {
        coordinator.isAuthenticated && !coordinator.isGuestMode
    }

    private var quota: CloudStorageQuota {
        isSignedIn ? .from(coordinator.billingEntitlement) : .init(usedBytes: nil, limitBytes: nil)
    }

    private var planLabel: String {
        coordinator.billingEntitlement?.storagePlan?.capitalized ?? "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if isSignedIn {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CURRENT PLAN")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                            Text(planLabel)
                                .font(.title2.weight(.bold))
                        }
                        Spacer()
                        Text(quota.percent.map { "\(Int($0.rounded()))%" } ?? "—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "EDF0E8"))
                            if let fraction = quota.ringFraction {
                                Capsule()
                                    .fill(quota.level.ringColor)
                                    .frame(width: geometry.size.width * fraction)
                            }
                        }
                    }
                    .frame(height: 10)
                    .accessibilityLabel("Cloud storage used")
                    .accessibilityValue(quota.percent.map { "\(Int($0.rounded())) percent" } ?? "Unavailable")

                    HStack {
                        Text("\(quota.usedLabel) used")
                        Spacer()
                        Text("\(quota.limitLabel) total")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: quota.level.isAlert ? "exclamationmark.triangle" : "cloud")
                            .font(.title3)
                            .foregroundStyle(quota.level.ringColor)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(quota.level.title).font(.subheadline.weight(.bold))
                            Text(quota.level.message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "F2F7E9"),
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                    if let error = coordinator.billingError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Button {
                        Task { await coordinator.refreshEntitlement() }
                    } label: {
                        Label(
                            coordinator.isCheckingEntitlement ? "Refreshing…" : "Refresh cloud usage",
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .disabled(coordinator.isCheckingEntitlement)

                    NavigationLink {
                        PlansView()
                    } label: {
                        Text(quota.level.isAlert ? "Get more space" : "View storage plans")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Sign in to sync your library and see your cloud storage quota. On-device storage is separate.")
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        AuthView()
                    } label: {
                        Text("Sign in")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "171711"), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle("Cloud storage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if isSignedIn { await coordinator.refreshEntitlement() }
        }
    }
}
