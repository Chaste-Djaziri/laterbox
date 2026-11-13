// laterbox-ios/LaterBoxMac/MacHelpView.swift
import SwiftUI
import AppKit

private struct MacSupportTicket: Decodable, Identifiable {
    let id: String
    let email: String
    let category: String
    let subject: String
    let message: String
    let platform: String
    let app_version: String?
    let status: String
    let created_at: String
}
private struct MacSupportTicketResponse: Decodable {
    let tickets: [MacSupportTicket]
}
private struct MacSupportSubmission: Decodable {
    let id: String
}
private struct MacHelpAnswer: Identifiable {
    let id: Int
    let question: String
    let answer: String
}
private let macHelpAnswers: [MacHelpAnswer] = [
    .init(id: 1, question: "How do I save a link, note, or task?",
          answer: "Click the + button in the sidebar or press Command-N. Follow the capture steps to add a link, text, or checklist and choose when it should return."),
    .init(id: 2, question: "What is the difference between Today, Upcoming, and Someday?",
          answer: "Today shows items that arrived in your Inbox in the last 24 hours. Upcoming shows items scheduled for tomorrow or later. Someday stores deferred items without a return date."),
    .init(id: 3, question: "How do I keep, star, or archive something?",
          answer: "Open an item's details to Keep it in your library, mark it Starred for quick access, or Archive it. These sections remain accessible in the Mac sidebar."),
    .init(id: 4, question: "Can I restore deleted items?",
          answer: "Yes. Open Recently Deleted, then choose Restore to Inbox. Delete Forever and Empty Trash permanently remove items and their uploaded files after confirmation."),
    .init(id: 5, question: "How do Collections work?",
          answer: "Click the folder icon to open the Collections popup, or choose View all Collections. You can create, rename, and delete folders. Add or remove an item using the folder control in Item Details."),
    .init(id: 6, question: "How do I sync items with Web and iPhone?",
          answer: "Sign in to the same LaterBox account on each platform. The Mac app synchronizes your cloud data using Supabase; use the cloud icon or Check Updates to request another refresh. Some functions require connectivity."),
    .init(id: 7, question: "What happens when I reach my cloud storage limit?",
          answer: "Your plan determines the available cloud attachment capacity. If your quota is full, new uploads may be paused until you free unused space. Your existing saved content is not automatically removed."),
    .init(id: 8, question: "Can Free users participate in Earn?",
          answer: "Eligible adults on Free or paid plans can participate when the Earn program is enabled. Whop identity verification and acceptance of the Earn Terms are required. Commissions depend on qualifying paid subscription renewals, not link clicks."),
    .init(id: 9, question: "Where can I change my referral code or see earnings?",
          answer: "Open Earn in the Mac sidebar. After Whop verification, you can copy or customize your code and inspect your referral and commission statuses. Payouts depend on the program's operating status."),
    .init(id: 10, question: "How do I report a bug or check a support request?",
          answer: "Use the Report tab here, choose a category, and describe what happened. A ticket reference is returned after successful submission. Check the Requests tab for your account's ticket statuses."),
]

struct MacHelpView: View {
    @ObservedObject var cloud: MacCloudSyncStore
    let accountEmail: String

    private enum Tab: String, CaseIterable {
        case faq = "FAQ"
        case report = "Report"
        case requests = "My requests"
    }
    @State private var tab: Tab = .faq
    @State private var search = ""
    @State private var email = ""
    @State private var category = "problem"
    @State private var subject = ""
    @State private var details = ""
    @State private var diagnostics = true
    @State private var busy = false
    @State private var ticketsLoading = false
    @State private var tickets: [MacSupportTicket] = []
    @State private var error: String?
    @State private var successID: String?
    @Environment(\.colorScheme) private var scheme

    private let lime = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    private var surface: Color { scheme == .dark ? Color(white: 0.16) : .white }
    private var muted: Color { scheme == .dark ? .white.opacity(0.61) : .black.opacity(0.56) }
    private var border: Color { scheme == .dark ? .white.opacity(0.12) : .black.opacity(0.10) }
    private var faqs: [MacHelpAnswer] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? macHelpAnswers : macHelpAnswers.filter {
            $0.question.localizedCaseInsensitiveContains(query) ||
            $0.answer.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Help & FAQ").font(.system(size: 25, weight: .bold))
                    Text("Find answers, report a problem, or follow up on support requests.")
                        .font(.system(size: 13)).foregroundStyle(muted)
                }
                Picker("Help sections", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 480)
                .onChange(of: tab) { _, next in
                    if next == .requests { Task { await refreshTickets() } }
                }
                switch tab {
                case .faq: faqContents
                case .report: reportContents
                case .requests: requestsContents
                }
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12)).foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
            .padding(23)
            .frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if email.isEmpty { email = accountEmail }
        }
        .task { await refreshTickets() }
    }

    private var faqContents: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(muted)
                TextField("Search questions and answers", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(14)
            .background(surface, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(border))

            if faqs.isEmpty {
                Text("No matching answers. You can send us a report instead.")
                    .font(.system(size: 13)).foregroundStyle(muted)
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
            ForEach(faqs) { faq in
                DisclosureGroup {
                    Text(faq.answer)
                        .font(.system(size: 12))
                        .foregroundStyle(muted)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 9)
                } label: {
                    Text(faq.question)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(scheme == .dark ? .white : .black)
                }
                .padding(16)
                .background(surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border))
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Still need assistance?").font(.system(size: 14, weight: .bold))
                    Text("Send a report to our support team.").font(.system(size: 12)).foregroundStyle(muted)
                }
                Spacer()
                Button("Report an issue") { tab = .report }
                    .buttonStyle(.borderedProminent)
                    .tint(lime)
            }
            .padding(18)
            .background(surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var reportContents: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Send a support report", systemImage: "envelope.badge")
                .font(.system(size: 16, weight: .bold))
            Text("Include the steps to reproduce a problem and any relevant error message. Do not send passwords or payment credentials.")
                .font(.system(size: 12)).foregroundStyle(muted)

            if let successID {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Report submitted successfully", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Reference: \(successID)")
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                    Button("View my requests") {
                        tab = .requests
                        Task { await refreshTickets() }
                    }
                    .buttonStyle(.link)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(lime, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.black)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("What can we help with?").font(.system(size: 12, weight: .semibold))
                Picker("Category", selection: $category) {
                    Text("Report a bug").tag("problem")
                    Text("Get help").tag("help")
                    Text("Share feedback").tag("feedback")
                    Text("Something else").tag("other")
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            field("Reply email") {
                TextField("you@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
            }
            field("Subject") {
                TextField("Short summary (3–160 characters)", text: $subject)
                    .textFieldStyle(.roundedBorder)
            }
            field("Description") {
                TextEditor(text: $details)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .frame(height: 140)
                    .padding(8)
                    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(border))
                Text("\(details.count) / 5,000 characters")
                    .font(.system(size: 11)).foregroundStyle(muted)
            }
            Toggle("Include app version and macOS version (no personal files)", isOn: $diagnostics)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
            HStack {
                Spacer()
                Button {
                    Task { await submit() }
                } label: {
                    Label(busy ? "Sending…" : "Submit report", systemImage: "paperplane.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(lime)
                .disabled(busy || !formIsValid)
            }
        }
        .padding(22)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border))
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content()
        }
    }

    private var formIsValid: Bool {
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let subj = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return mail.contains("@") && mail.contains(".") && mail.count <= 254 &&
            (3...160).contains(subj.count) && (10...5000).contains(body.count)
    }

    private var requestsContents: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your support requests").font(.system(size: 16, weight: .bold))
                Spacer()
                Button {
                    Task { await refreshTickets() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .disabled(ticketsLoading)
            }
            if ticketsLoading && tickets.isEmpty {
                ProgressView("Loading requests…")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if tickets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 28)).foregroundStyle(muted)
                    Text("No support requests yet")
                        .font(.system(size: 14, weight: .semibold))
                    Button("Create a report") { tab = .report }
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, minHeight: 170)
            } else {
                ForEach(tickets) { ticket in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(ticket.subject).font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text(ticket.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(lime.opacity(0.5), in: Capsule())
                        }
                        HStack(spacing: 12) {
                            Text(ticket.category.capitalized)
                            Text(ticket.platform == "macos" ? "macOS" : ticket.platform.capitalized)
                            if let date = ISO8601DateFormatter().date(from: ticket.created_at) {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                        .font(.system(size: 11)).foregroundStyle(muted)
                        Text(ticket.message)
                            .font(.system(size: 12))
                            .foregroundStyle(muted)
                            .lineLimit(3)
                        HStack {
                            Text("ID: \(ticket.id)")
                                .font(.system(size: 10, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(ticket.id, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Copy ticket ID")
                        }
                    }
                    .padding(16)
                    .background(surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border))
                }
            }
        }
    }

    private func submit() async {
        guard !busy && formIsValid else { return }
        busy = true
        error = nil
        successID = nil
        defer { busy = false }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let diagnosticText = diagnostics
            ? "LaterBox Mac \(version) (macOS \(ProcessInfo.processInfo.operatingSystemVersionString))"
            : "LaterBox Mac \(version)"
        do {
            let result = try await cloud.supportAPI(method: "POST", body: [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
                "category": category,
                "subject": subject.trimmingCharacters(in: .whitespacesAndNewlines),
                "message": details.trimmingCharacters(in: .whitespacesAndNewlines),
                "platform": "macos",
                "appVersion": String(diagnosticText.prefix(100))
            ])
            successID = try JSONDecoder().decode(MacSupportSubmission.self, from: result).id
            subject = ""
            details = ""
            await refreshTickets()
        } catch { self.error = error.localizedDescription }
    }

    private func refreshTickets() async {
        guard !ticketsLoading else { return }
        ticketsLoading = true
        defer { ticketsLoading = false }
        do {
            let result = try await cloud.supportAPI()
            tickets = try JSONDecoder().decode(MacSupportTicketResponse.self, from: result).tickets
        } catch {
            self.error = error.localizedDescription
        }
    }
}
