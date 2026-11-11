// laterbox-ios/LaterBoxMac/LaterBoxMacApp.swift
import SwiftUI
import Security
import AuthenticationServices
import AppKit

private enum MacColors {
    static let accent = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
}

@main
struct LaterBoxMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacLoginView()
                .frame(minWidth: 430, minHeight: 480)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 550, height: 620)
        .windowResizability(.contentMinSize)
    }
}

private struct MacAuthResponse: Decodable {
    let access_token: String?
    let refresh_token: String?
}

private struct MacAuthError: Decodable {
    let msg: String?
    let message: String?
    let error_description: String?
}

@MainActor
private final class MacAuthModel: ObservableObject {
    enum Step { case email, password, signup, verify, authenticated }
    @Published var step: Step = .email
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var code = ""
    @Published var busy = false
    @Published var error: String?
    @Published var info: String?
    @Published var showPassword = false

    private let base = "https://ltjisrgldssqskcylcbj.supabase.co"
    private let publicKey = "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"
    private let callbackScheme = "laterbox-macos"
    private let redirect = "laterbox-macos://auth-callback"
    private var oauthSession: ASWebAuthenticationSession?

    var isValid: Bool {
        let validEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
        switch step {
        case .email: return validEmail
        case .password: return !password.isEmpty
        case .signup: return validEmail && password.count >= 6 && password == confirmPassword
        case .verify: return code.count == 8
        case .authenticated: return true
        }
    }

    func submit() {
        guard isValid, !busy else { return }
        error = nil
        info = nil
        switch step {
        case .email:
            email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            step = .password
        case .password: Task { await signIn() }
        case .signup: Task { await signUp() }
        case .verify: Task { await verify() }
        case .authenticated: break
        }
    }

    func showSignup() {
        error = nil
        info = nil
        password = ""
        confirmPassword = ""
        step = .signup
    }

    func showSignIn() {
        error = nil
        info = nil
        password = ""
        confirmPassword = ""
        step = .email
    }

    func back() {
        error = nil
        info = nil
        if step == .verify { step = .signup }
        else { step = .email }
    }

    func sendSignInCode() {
        Task {
            await perform {
                _ = try await post("/auth/v1/otp", body: ["email": email, "create_user": false])
                self.step = .verify
                self.info = "Check your email for the verification code."
            }
        }
    }

    private func post(_ path: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(publicKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(response.statusCode) else {
            let payload = try? JSONDecoder().decode(MacAuthError.self, from: data)
            throw NSError(domain: "LaterBoxAuth", code: response.statusCode, userInfo: [
                NSLocalizedDescriptionKey: payload?.msg ?? payload?.message ?? payload?.error_description ?? "Authentication failed."
            ])
        }
        return data
    }

    private func perform(_ action: () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do { try await action() }
        catch { self.error = error.localizedDescription }
    }

    private func signIn() async {
        await perform {
            let data = try await post("/auth/v1/token?grant_type=password", body: [
                "email": email, "password": password
            ])
            try storeSession(data)
            password = ""
            step = .authenticated
        }
    }

    private func signUp() async {
        await perform {
            let data = try await post("/auth/v1/signup", body: [
                "email": email, "password": password
            ])
            let tokens = try JSONDecoder().decode(MacAuthResponse.self, from: data)
            if tokens.access_token != nil {
                try storeSession(data)
                password = ""
                confirmPassword = ""
                step = .authenticated
            } else {
                code = ""
                step = .verify
                info = "Check your email for the verification code."
            }
        }
    }

    private func verify() async {
        await perform {
            do {
                let data = try await post("/auth/v1/verify", body: [
                    "email": email, "token": code, "type": "signup"
                ])
                try storeSession(data)
            } catch {
                // Existing email/password users may use email OTP instead of signup.
                let data = try await post("/auth/v1/verify", body: [
                    "email": email, "token": code, "type": "email"
                ])
                try storeSession(data)
            }
            password = ""
            confirmPassword = ""
            code = ""
            step = .authenticated
        }
    }

    func signIn(provider: String) {
        guard !busy, ["google", "apple"].contains(provider) else { return }
        error = nil
        info = nil
        guard var url = URLComponents(string: base + "/auth/v1/authorize") else { return }
        url.queryItems = [
            URLQueryItem(name: "provider", value: provider),
            URLQueryItem(name: "redirect_to", value: redirect)
        ]
        guard let authorizationURL = url.url else { return }
        busy = true
        let session = ASWebAuthenticationSession(url: authorizationURL,
                                                 callbackURLScheme: callbackScheme) { [weak self] callback, failure in
            Task { @MainActor in
                guard let self else { return }
                self.busy = false
                self.oauthSession = nil
                if let failure {
                    if (failure as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.error = failure.localizedDescription
                    }
                    return
                }
                guard let callback else {
                    self.error = "Sign in did not finish."
                    return
                }
                do {
                    try self.handleOAuthCallback(callback)
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
        session.presentationContextProvider = MacOAuthWindowProvider.shared
        session.prefersEphemeralWebBrowserSession = false
        oauthSession = session
        if !session.start() {
            busy = false
            oauthSession = nil
            error = "Could not open the sign-in window."
        }
    }

    private func handleOAuthCallback(_ callback: URL) throws {
        // Supabase browser OAuth returns session tokens in the redirect fragment.
        // Never treat a callback without tokens as a successful login.
        let fragment = URLComponents(string: "https://localhost/?" + (callback.fragment ?? ""))
        let items = fragment?.queryItems ?? []
        let values = Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
        if let message = values["error_description"] ?? values["error"] {
            throw NSError(domain: "LaterBoxOAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        guard let token = values["access_token"], !token.isEmpty else {
            throw NSError(domain: "LaterBoxOAuth", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No session was returned. Check the macOS OAuth redirect URL in Supabase."
            ])
        }
        try saveCredentials(access: token, refresh: values["refresh_token"])
        step = .authenticated
    }

    private func storeSession(_ data: Data) throws {
        let tokens = try JSONDecoder().decode(MacAuthResponse.self, from: data)
        guard let access = tokens.access_token, !access.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        try saveCredentials(access: access, refresh: tokens.refresh_token)
    }

    private func saveCredentials(access: String, refresh: String?) throws {
        let value = try JSONEncoder().encode(["access_token": access, "refresh_token": refresh ?? ""])
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "laterbox-macos-session"
        ]
        SecItemDelete(lookup as CFDictionary)
        var insert = lookup
        insert[kSecValueData as String] = value
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "Unable to save your sign-in securely."])
        }
    }

    func signOut() {
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "laterbox-macos-session"
        ]
        SecItemDelete(lookup as CFDictionary)
        password = ""
        confirmPassword = ""
        code = ""
        showSignIn()
    }
}

private final class MacOAuthWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = MacOAuthWindowProvider()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
    }
}


private struct MacWindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { configure(view.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        for type in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(type)?.isHidden = true
        }
    }
}

private struct MacEmailInput: View {
    @Binding var email: String
    let submit: () -> Void
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "envelope")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(focused ? .primary : .secondary)
                .frame(width: 19)
                .accessibilityHidden(true)
            TextField("Email address", text: $email)
                .font(.system(size: 14))
                .textContentType(.emailAddress)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit(submit)
                .accessibilityIdentifier("mac.auth.email")
            if !email.isEmpty {
                Button {
                    email = ""
                    focused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear email")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.055) : Color.white,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    focused ? Color.primary.opacity(0.65) : Color.primary.opacity(0.13),
                    lineWidth: focused ? 1.5 : 1
                )
        }
        .animation(.easeOut(duration: 0.16), value: focused)
    }
}

struct MacLoginView: View {
    @StateObject private var auth = MacAuthModel()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismissWindow) private var dismissWindow

    private var title: String {
        switch auth.step {
        case .email, .password: return "Sign in"
        case .signup: return "Create account"
        case .verify: return "Verify email"
        case .authenticated: return "Signed in"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Spacer(minLength: 18)
            VStack(spacing: 22) {
                HStack(spacing: 9) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 39, height: 39)
                        .background(MacColors.accent, in: RoundedRectangle(cornerRadius: 12))
                    Text("laterbox")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .tracking(-1)
                }
                Text(title)
                    .font(.system(size: 25, weight: .semibold))
                    .tracking(-0.6)

                if auth.step == .authenticated {
                    Button("Sign out", action: auth.signOut)
                        .buttonStyle(.bordered)
                } else {
                    VStack(spacing: 12) {
                        if auth.step == .email || auth.step == .signup {
                            MacEmailInput(email: $auth.email, submit: auth.submit)
                        } else {
                            HStack {
                                Text(auth.email)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Change", action: auth.showSignIn)
                                    .font(.system(size: 12))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if auth.step == .password || auth.step == .signup {
                            HStack {
                                Group {
                                    if auth.showPassword {
                                        TextField("Password", text: $auth.password)
                                    } else {
                                        SecureField("Password", text: $auth.password)
                                    }
                                }
                                .onSubmit(auth.submit)
                                Button {
                                    auth.showPassword.toggle()
                                } label: {
                                    Image(systemName: auth.showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if auth.step == .signup {
                            SecureField("Confirm password", text: $auth.confirmPassword)
                                .onSubmit(auth.submit)
                        }

                        if auth.step == .verify {
                            TextField("8-digit code", text: $auth.code)
                                .onChange(of: auth.code) { _, value in
                                    auth.code = String(value.filter(\.isNumber).prefix(8))
                                }
                                .onSubmit(auth.submit)
                        }

                        if let error = auth.error {
                            Text(error).foregroundStyle(.red).font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let info = auth.info {
                            Text(info).foregroundStyle(.secondary).font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: auth.submit) {
                            HStack(spacing: 8) {
                                if auth.busy { ProgressView().controlSize(.small) }
                                Text(auth.step == .email ? "Continue" :
                                        auth.step == .signup ? "Create account" :
                                        auth.step == .verify ? "Verify" : "Sign in")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(MacColors.accent, in: RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                        .disabled(auth.busy || !auth.isValid)
                        .opacity(auth.busy || !auth.isValid ? 0.5 : 1)

                        if auth.step == .password {
                            Button("Use email code", action: auth.sendSignInCode)
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }

                        if auth.step == .email || auth.step == .signup {
                            HStack(spacing: 12) {
                                Rectangle().fill(.quaternary).frame(height: 1)
                                Text("or").font(.system(size: 12)).foregroundStyle(.secondary)
                                Rectangle().fill(.quaternary).frame(height: 1)
                            }
                            .padding(.vertical, 3)

                            providerButton("Continue with Google", symbol: "g.circle.fill", provider: "google")
                            providerButton("Continue with Apple", symbol: "apple.logo", provider: "apple")
                        }

                        if auth.step == .email {
                            HStack(spacing: 4) {
                                Text("No account?")
                                    .foregroundStyle(.secondary)
                                Button("Sign up", action: auth.showSignup)
                                    .fontWeight(.semibold)
                                    .buttonStyle(.plain)
                            }
                            .font(.system(size: 12))
                            .padding(.top, 6)
                        } else if auth.step == .signup {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundStyle(.secondary)
                                Button("Sign in", action: auth.showSignIn)
                                    .fontWeight(.semibold)
                                    .buttonStyle(.plain)
                            }
                            .font(.system(size: 12))
                            .padding(.top, 6)
                        } else if auth.step == .verify {
                            Button("Back", action: auth.back)
                                .font(.system(size: 12))
                                .buttonStyle(.plain)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: 330)
            Spacer(minLength: 18)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))

            Button {
                NSApp.keyWindow?.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close LaterBox")
            .padding(.leading, 20)
            .padding(.top, 20)
        }
        .background(MacWindowChrome().frame(width: 0, height: 0))
    }

    private func providerButton(_ title: String, symbol: String, provider: String) -> some View {
        Button { auth.signIn(provider: provider) } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol).font(.system(size: 16))
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.primary.opacity(0.12)))
        .disabled(auth.busy)
    }
}

#Preview {
    MacLoginView().frame(width: 550, height: 620)
}
