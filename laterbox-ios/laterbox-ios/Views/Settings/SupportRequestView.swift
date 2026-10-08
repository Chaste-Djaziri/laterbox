import SwiftUI

struct SupportRequestView: View {
    @State private var email = SyncCoordinator.shared.currentUserEmail ?? ""
    @State private var category = "problem"
    @State private var subject = ""
    @State private var message = ""
    @State private var sending = false
    @State private var error: String?
    @State private var reference: String?

    private var valid: Bool {
        email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil && email.count <= 254 &&
        (3...160).contains(subject.trimmingCharacters(in: .whitespacesAndNewlines).count) &&
        (10...5000).contains(message.trimmingCharacters(in: .whitespacesAndNewlines).count)
    }

    var body: some View {
        Form {
            if let reference {
                Section {
                    Label("Request received", systemImage: "checkmark.circle.fill")
                    Text("We can reply to \(email).")
                    Text("Reference: \(reference)").font(.caption).textSelection(.enabled)
                    Button("Send another request") { self.reference = nil }
                }
            } else {
                Section {
                    Text("Tell us what happened or how we can help. Include steps to reproduce a problem. Please leave out passwords and sensitive information.")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    Picker("What do you need?", selection: $category) {
                        Text("Report a problem").tag("problem")
                        Text("I need help").tag("help")
                        Text("Feedback or suggestion").tag("feedback")
                        Text("Something else").tag("other")
                    }
                    TextField("Reply email", text: $email)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityLabel("Reply email")
                    TextField("Subject", text: $subject).accessibilityLabel("Subject")
                }
                Section("Message") {
                    TextEditor(text: $message).frame(minHeight: 180).accessibilityLabel("Message")
                    Text("\(message.count)/5,000 characters · At least 10 characters")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Section {
                    Button { Task { await submit() } } label: {
                        HStack {
                            Text(sending ? "Sending…" : "Send request")
                            Spacer()
                            if sending { ProgressView() }
                        }
                    }
                    .disabled(!valid || sending)
                    if let error { Text(error).foregroundStyle(.red).accessibilityLabel(error) }
                } footer: {
                    Text("Your email, message, platform, and app version are saved with this request.")
                }
            }
        }
        .disabled(sending)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Help & Report a Problem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    @MainActor
    private func submit() async {
        guard valid, !sending else { return }
        sending = true; error = nil
        defer { sending = false }
        do {
            guard let url = URL(string: "\(LaterBoxAPIService.shared.webUrl)/api/support") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = SyncCoordinator.shared.authToken, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try JSONEncoder().encode([
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines), "category": category,
                "subject": subject, "message": message, "platform": "ios", "appVersion": AppVersion.displayString
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
            guard (response as? HTTPURLResponse)?.statusCode == 201, let id = payload?["id"] else {
                error = payload?["error"] ?? "We could not send your request. Please try again."
                return
            }
            reference = id; subject = ""; message = ""
        } catch {
            self.error = "We could not send your request. Check your connection and try again."
        }
    }
}
