// laterbox-ios/LaterBoxMac/LaterBoxMacApp.swift
import SwiftUI
import Security

private enum MacPalette {
    static let accent = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
    static let background = Color(nsColor: .windowBackgroundColor)
}

@main
struct LaterBoxMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacLoginView()
                .frame(minWidth: 780, minHeight: 540)
        }
        .defaultSize(width: 940, height: 640)
        .windowResizability(.contentMinSize)
    }
}

private struct MacAuthSession: Decodable {
    let access_token: String
    let refresh_token: String?
}

private struct MacAuthError: Decodable {
    let msg: String?
    let message: String?
    let error_description: String?
}

@MainActor
private final class MacAuthModel: ObservableObject {
    enum Step { case email, password, code, authenticated }
    @Published var step: Step = .email
    @Published var email = ""
    @Published var password = ""
    @Published var code = ""
    @Published var busy = false
    @Published var error: String?
    @Published var showPassword = false

    private let base = "https://ltjisrgldssqskcylcbj.supabase.co"
    // This is the public Supabase publishable key, not a server-side secret.
    private let publicKey = "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"

    var isValid: Bool {
        switch step {
        case .email: return email.contains("@") && email.contains(".")
        case .password: return !password.isEmpty
        case .code: return code.count == 8
        case .authenticated: return true
        }
    }

    func proceed() {
        guard !busy else { return }
        error = nil
        switch step {
        case .email:
            email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard isValid else { return }
            step = .password
        case .password:
            Task { await signIn() }
        case .code:
            Task { await verifyCode() }
        case .authenticated: break
        }
    }

    func sendCode() { Task { await requestCode() } }

    private func post(_ path: String, data: [String: Any]) async throws -> Data {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(publicKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            let payload = try? JSONDecoder().decode(MacAuthError.self, from: responseData)
            throw NSError(domain: "LaterBoxLogin", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: payload?.msg ?? payload?.message ?? payload?.error_description ?? "Sign in failed. Please try again."
            ])
        }
        return responseData
    }

    private func perform(_ work: () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do { try await work() }
        catch { self.error = error.localizedDescription }
    }

    private func signIn() async {
        await perform {
            let result = try await post("/auth/v1/token?grant_type=password", data: [
                "email": email, "password": password
            ])
            try storeSession(result)
            password = ""
            step = .authenticated
        }
    }

    private func requestCode() async {
        await perform {
            _ = try await post("/auth/v1/otp", data: ["email": email, "create_user": false])
            password = ""
            step = .code
        }
    }

    private func verifyCode() async {
        await perform {
            let result = try await post("/auth/v1/verify", data: [
                "email": email, "token": code, "type": "email"
            ])
            try storeSession(result)
            code = ""
            step = .authenticated
        }
    }

    private func storeSession(_ data: Data) throws {
        let session = try JSONDecoder().decode(MacAuthSession.self, from: data)
        guard !session.access_token.isEmpty else { throw URLError(.userAuthenticationRequired) }
        // Credentials are stored only in this app's Keychain and never in UserDefaults.
        let credentials = try JSONEncoder().encode([
            "access_token": session.access_token,
            "refresh_token": session.refresh_token ?? ""
        ])
        let account = "laterbox-macos-session"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        let insert: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: account,
                                     kSecValueData as String: credentials]
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "Could not securely save the session."])
        }
    }

    func signOut() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: "laterbox-macos-session"]
        SecItemDelete(query as CFDictionary)
        step = .email
        password = ""
        code = ""
    }
}

struct MacLoginView: View {
    @StateObject private var auth = MacAuthModel()
    @Environment(\.colorScheme) private var scheme
    private var muted: Color { .secondary }
    private var dark: Bool { scheme == .dark }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(MacPalette.accent, in: RoundedRectangle(cornerRadius: 12))
                    Text("laterbox")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .tracking(-1)
                }

                Spacer(minLength: 45)

                VStack(alignment: .leading, spacing: 10) {
                    Text(auth.step == .authenticated ? "You're signed in." : auth.step == .code ? "Check your inbox." : "Welcome back.")
                        .font(.system(size: 36, weight: .bold))
                        .tracking(-1.4)
                    Text(auth.step == .authenticated
                         ? "Your Mac is connected. The desktop inbox is coming next."
                         : auth.step == .code
                         ? "Enter the 8-digit verification code sent to \(auth.email)."
                         : "Everything worth keeping, in one calm place.")
                        .font(.system(size: 14))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 32)

                if auth.step == .authenticated {
                    Button("Sign out", action: auth.signOut)
                        .buttonStyle(.borderedProminent)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        if auth.step == .email {
                            fieldLabel("Email address")
                            TextField("you@example.com", text: $auth.email)
                                .textContentType(.emailAddress)
                                .onSubmit(auth.proceed)
                                .accessibilityIdentifier("mac.auth.email")
                        } else if auth.step == .password {
                            fieldLabel("Password")
                            HStack {
                                Group {
                                    if auth.showPassword {
                                        TextField("Your password", text: $auth.password)
                                    } else {
                                        SecureField("Your password", text: $auth.password)
                                    }
                                }
                                .onSubmit(auth.proceed)
                                Button {
                                    auth.showPassword.toggle()
                                } label: {
                                    Image(systemName: auth.showPassword ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.plain)
                            }
                            Button("Use an email code instead", action: auth.sendCode)
                                .buttonStyle(.link)
                                .font(.system(size: 12))
                        } else {
                            fieldLabel("Verification code")
                            TextField("8-digit code", text: $auth.code)
                                .onChange(of: auth.code) { _, v in
                                    auth.code = String(v.filter(\.isNumber).prefix(8))
                                }
                                .onSubmit(auth.proceed)
                        }

                        if let error = auth.error {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.system(size: 12))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button(action: auth.proceed) {
                            HStack(spacing: 8) {
                                if auth.busy { ProgressView().controlSize(.small) }
                                Text(auth.step == .email ? "Continue" : auth.step == .code ? "Verify code" : "Sign in")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black)
                        .background(MacPalette.accent, in: RoundedRectangle(cornerRadius: 10))
                        .disabled(!auth.isValid || auth.busy)
                        .opacity(auth.isValid && !auth.busy ? 1 : 0.55)

                        if auth.step != .email {
                            Button("Back", action: { auth.step = .email; auth.error = nil })
                                .buttonStyle(.link)
                                .font(.system(size: 12))
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                }

                Spacer(minLength: 30)

                HStack(spacing: 5) {
                    Text("New to LaterBox?")
                    Link("Create an account", destination: URL(string: "https://laterbox.dev")!)
                }
                .font(.system(size: 12))
                .foregroundStyle(muted)
            }
            .padding(52)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            ZStack(alignment: .bottomLeading) {
                (dark ? Color(red: 0.16, green: 0.18, blue: 0.15) : Color(red: 0.92, green: 0.94, blue: 0.86))
                Circle()
                    .fill(MacPalette.accent.opacity(0.6))
                    .frame(width: 390, height: 390)
                    .blur(radius: 70)
                    .offset(x: 100, y: -80)
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 40))
                    Text("Save now.\nFind it when it matters.")
                        .font(.system(size: 32, weight: .semibold))
                        .tracking(-1)
                    Text("Your links, ideas, articles and things to revisit — always within reach.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(42)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(MacPalette.background)
    }

    private func fieldLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .semibold))
    }
}

#Preview {
    MacLoginView()
        .frame(width: 940, height: 640)
}
