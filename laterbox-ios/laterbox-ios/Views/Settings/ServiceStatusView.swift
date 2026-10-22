import SwiftUI

struct ServiceStatusView: View {
    private enum HistorySelection: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case custom = "Custom"

        var id: String { rawValue }
    }

    @State private var snapshot: ServiceStatusSnapshot?
    @State private var history: ServiceUptimeHistory?
    @State private var selectedHistory = HistorySelection.week
    @State private var customFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customTo = Date()
    @State private var refreshing = false
    @State private var loadingHistory = false
    @State private var failed = false
    @State private var historyFailed = false

    var body: some View {
        List {
            if failed {
                Section {
                    Label("Couldn’t refresh service status", systemImage: "wifi.exclamationmark")
                        .font(.subheadline.weight(.semibold))
                    Text(snapshot == nil ? "Check your connection and try again." : "The last available results are shown below. Check your connection and try again.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Try again") { Task { await refresh() } }.disabled(refreshing)
                }
            }
            if let snapshot {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: snapshot.status == "operational" ? "checkmark.circle.fill" : "waveform.path.ecg")
                            .font(.system(size: 30)).foregroundStyle(color(snapshot.status))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(snapshot.label).font(.headline)
                            Text("\(snapshot.monitors.count) services monitored").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } footer: {
                    if let date = snapshot.refreshedAt {
                        Text("Updated \(date.formatted(date: .abbreviated, time: .shortened))")
                    }
                }

                Section("Uptime history") {
                    Picker("Range", selection: $selectedHistory) {
                        ForEach(HistorySelection.allCases) { selection in
                            Text(selection.rawValue).tag(selection)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedHistory) { _, _ in
                        Task { await refreshHistory() }
                    }

                    if selectedHistory == .custom {
                        DatePicker("From", selection: $customFrom, in: ...Date(), displayedComponents: .date)
                        DatePicker("To", selection: $customTo, in: customFrom...Date(), displayedComponents: .date)
                            .onChange(of: customFrom) { _, newValue in
                                if customTo < newValue { customTo = newValue }
                            }
                        Button("Load custom range") {
                            Task { await refreshHistory() }
                        }
                        .disabled(loadingHistory || customFrom >= customTo)
                    }

                    if loadingHistory {
                        HStack { Spacer(); ProgressView("Loading uptime…"); Spacer() }
                            .padding(.vertical, 12)
                    } else if historyFailed {
                        Label("Uptime history is temporarily unavailable.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let history {
                        Text(historySummary(history))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("All monitors") {
                    if snapshot.monitors.isEmpty {
                        Text("No monitors are available yet.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.monitors) { monitor in
                        monitorRow(monitor, history: history?.monitors.first { $0.id == monitor.id })
                    }
                }
            } else if refreshing {
                Section { HStack { Spacer(); ProgressView("Loading monitors…"); Spacer() }.padding(.vertical, 24) }
            }
            Section {
                Link(destination: URL(string: "https://status.laterbox.dev")!) {
                    Label("Open public status page", systemImage: "arrow.up.right.square")
                }
            } footer: { Text("Service health provided by Better Stack. Pull down to refresh.") }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvasBackground.ignoresSafeArea())
        .navigationTitle("Service Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await refresh() } } label: {
                    if refreshing { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                }.disabled(refreshing).accessibilityLabel("Refresh service status")
            }
        }
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    @ViewBuilder
    private func monitorRow(_ monitor: ServiceMonitorStatus, history: MonitorUptimeHistory?) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                Circle().fill(color(monitor.status)).frame(width: 9, height: 9).padding(.top, 5)
                VStack(alignment: .leading, spacing: 7) {
                    Text(monitor.name).font(.subheadline.weight(.semibold))
                    Text(monitor.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color(monitor.status))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(color(monitor.status).opacity(0.1), in: Capsule())
                    if let checked = monitor.lastCheck {
                        Text("Last check: \(checked.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    if let frequency = monitor.checkFrequency {
                        Text(frequency % 60 == 0 ? "Checks every \(frequency / 60) min" : "Checks every \(frequency) sec")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            if let history {
                HStack {
                    Text(history.availability.map { "\(Int($0.rounded()))% uptime" } ?? "Uptime unavailable")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    if let downtime = history.downtimeSeconds, downtime > 0 {
                        Text("\(formatDowntime(downtime)) downtime")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                uptimeBars(history.buckets)
            }
        }
        .padding(.vertical, 5)
    }

    private func uptimeBars(_ buckets: [UptimeBucket]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(buckets) { bucket in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(bucketColor(bucket.availability))
                        .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                        .accessibilityLabel(bucketLabel(bucket))
                }
            }
            if let first = buckets.first?.date, let last = buckets.last?.date {
                HStack {
                    Text(first.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(last.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func bucketLabel(_ bucket: UptimeBucket) -> String {
        let date = bucket.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown time"
        guard let availability = bucket.availability else { return "\(date): uptime unavailable" }
        return "\(date): \(Int(availability.rounded()))% uptime"
    }

    private func historySummary(_ history: ServiceUptimeHistory) -> String {
        let from = ServiceStatusSnapshot.date(history.from)?.formatted(date: .abbreviated, time: .omitted) ?? history.from
        let to = ServiceStatusSnapshot.date(history.to)?.formatted(date: .abbreviated, time: .omitted) ?? history.to
        return "\(from) – \(to) • \(history.unit == "hour" ? "Hourly" : "Daily") bars"
    }

    private func bucketColor(_ availability: Double?) -> Color {
        guard let availability else { return .gray.opacity(0.35) }
        if availability >= 99.9 { return .green }
        if availability >= 99 { return .yellow }
        return .red
    }

    private func formatDowntime(_ seconds: Double) -> String {
        if seconds < 60 { return "\(Int(seconds))s" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }

    private func color(_ status: String) -> Color {
        switch status {
        case "up", "operational": return .green
        case "down", "outage": return .red
        case "validating", "degraded", "maintenance": return .orange
        default: return .secondary
        }
    }

    private func rangeDates() -> (from: Date, to: Date) {
        let now = Date()
        switch selectedHistory {
        case .day:
            return (Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now, now)
        case .week:
            return (Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now, now)
        case .month:
            return (Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now, now)
        case .custom:
            return (Calendar.current.startOfDay(for: customFrom), Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: customTo) ?? customTo)
        }
    }

    @MainActor private func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        do {
            let fresh = try await LaterBoxAPIService.shared.fetchServiceStatus()
            guard !Task.isCancelled else { return }
            snapshot = fresh
            failed = false
            await refreshHistory()
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }

    @MainActor private func refreshHistory() async {
        guard snapshot != nil, !loadingHistory else { return }
        loadingHistory = true
        historyFailed = false
        defer { loadingHistory = false }
        do {
            let range = rangeDates()
            history = try await LaterBoxAPIService.shared.fetchUptimeHistory(
                from: range.from,
                to: range.to,
                timeZone: TimeZone.current.identifier
            )
        } catch {
            if !Task.isCancelled { historyFailed = true }
        }
    }
}
