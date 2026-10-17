import SwiftUI

struct ServiceStatusView: View {
    @State private var snapshot: ServiceStatusSnapshot?
    @State private var refreshing = false
    @State private var failed = false

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

                Section("All monitors") {
                    if snapshot.monitors.isEmpty {
                        Text("No monitors are available yet.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.monitors) { monitor in
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
                        .padding(.vertical, 5)
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

    private func color(_ status: String) -> Color {
        switch status {
        case "up", "operational": return .green
        case "down", "outage": return .red
        case "validating", "degraded", "maintenance": return .orange
        default: return .secondary
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
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}
