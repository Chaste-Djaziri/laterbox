// laterbox-ios/LaterBoxMac/LaterBoxMacApp.swift
import SwiftUI
import Security
import AuthenticationServices
import AppKit

import Carbon
import ServiceManagement

// A system-wide Carbon hotkey works without Accessibility or Input Monitoring.
// Closing the main window leaves LaterBox running, so this hotkey stays active.
@MainActor
final class LaterBoxMacDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var capturePanel: NSPanel?
    private let captureCloud = MacCloudSyncStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installCaptureHotkey()
        // User requested background capture across logins. macOS controls the
        // approval in Login Items; failure must not block normal app launch.
        if SMAppService.mainApp.status == .notRegistered {
            do { try SMAppService.mainApp.register() }
            catch { NSLog("LaterBox: Enable Open at Login in System Settings: %@", error.localizedDescription) }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let hotKeyHandler { RemoveEventHandler(hotKeyHandler) }
    }

    private func installCaptureHotkey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, _ in
            guard let event else { return noErr }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, UInt32(kEventParamDirectObject),
                                           UInt32(typeEventHotKeyID), nil,
                                           MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.id == 1 else { return OSStatus(eventNotHandledErr) }
            DispatchQueue.main.async {
                (NSApp.delegate as? LaterBoxMacDelegate)?.showQuickCapture()
            }
            return noErr
        }
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), handler,
                                                1, &eventType, nil, &hotKeyHandler)
        guard installStatus == noErr else {
            NSLog("LaterBox: Could not install capture hotkey handler (%d)", installStatus)
            return
        }
        let id = EventHotKeyID(signature: OSType(0x4C425843), id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_N),
                                        UInt32(cmdKey | optionKey), id,
                                        GetApplicationEventTarget(), 0, &hotKey)
        if status != noErr {
            NSLog("LaterBox: Command-Option-N is unavailable (%d)", status)
        }
    }

    func showQuickCapture() {
        if let capturePanel, capturePanel.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            capturePanel.makeKeyAndOrderFront(nil)
            return
        }
        // A new view on each invocation clears the previous completed draft.
        let capture = MacQuickSaveView(onSave: { [weak self] draft in
            guard let self else { throw MacCloudError.notSignedIn }
            try await self.captureCloud.save(draft)
        }, onClose: { [weak self] in
            self?.capturePanel?.close()
        })
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 570, height: 595),
                            styleMask: [.titled, .closable, .fullSizeContentView],
                            backing: .buffered, defer: false)
        panel.title = "LaterBox Quick Capture"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: capture
            .preferredColorScheme(MacAppearanceSettings.shared.colorScheme))
        panel.center()
        capturePanel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}


private enum MacColors {
    static let accent = Color(red: 230 / 255, green: 237 / 255, blue: 176 / 255)
}

// Apply the saved appearance to the actual macOS NSWindow, including window
// chrome and native popup controls. Re-applies whenever the setting changes.
struct MacThemeWindowBridge: NSViewRepresentable {
    let appearance: String

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ view: NSView, context: Context) {
        // A view may enter the window after the first update. The asynchronous
        // dispatch also avoids changing window appearance during SwiftUI layout.
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            switch appearance {
            case "light": window.appearance = NSAppearance(named: .aqua)
            case "dark": window.appearance = NSAppearance(named: .darkAqua)
            default: window.appearance = nil
            }
        }
    }
}

// Matches the deterministic graphite texture used by InboxGrainBackground on iOS.
private struct MacAuthCanvas: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            if scheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 34 / 255, green: 36 / 255, blue: 39 / 255),
                        Color(red: 27 / 255, green: 29 / 255, blue: 32 / 255),
                        Color(red: 23 / 255, green: 25 / 255, blue: 27 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                    guard size.width > 0, size.height > 0 else { return }
                    var highlights = Path()
                    var shadows = Path()
                    let count = min(9_000, Int(size.width * size.height / 62))
                    for index in 0..<count {
                        let seed = UInt64(index)
                        let x = Self.noise(seed &* 3 &+ 11) * size.width
                        let y = Self.noise(seed &* 3 &+ 12) * size.height
                        let diameter = 0.6 + Self.noise(seed &* 3 &+ 13) * 0.8
                        let dot = CGRect(x: x, y: y, width: diameter, height: diameter)
                        if index.isMultiple(of: 2) {
                            highlights.addRect(dot)
                        } else {
                            shadows.addRect(dot)
                        }
                    }
                    context.fill(highlights, with: .color(.white.opacity(0.075)))
                    context.fill(shadows, with: .color(.black.opacity(0.16)))
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            } else {
                Color(red: 248 / 255, green: 249 / 255, blue: 245 / 255)
            }
        }
    }

    private static func noise(_ value: UInt64) -> CGFloat {
        var seed = value &+ 0x9E3779B97F4A7C15
        seed = (seed ^ (seed >> 30)) &* 0xBF58476D1CE4E5B9
        seed = (seed ^ (seed >> 27)) &* 0x94D049BB133111EB
        seed ^= seed >> 31
        return CGFloat(seed & 0xFFFF) / 65_535
    }
}

/// Single source of truth for the Mac appearance preference. Store a real
/// value in the app's standard defaults domain and publish changes immediately.
@MainActor
final class MacAppearanceSettings: ObservableObject {
    static let shared = MacAppearanceSettings()
    static let key = "laterbox.mac.appearance"
    @Published var mode: String {
        didSet {
            guard mode != oldValue else { return }
            let normalized = Self.normalized(mode)
            if normalized != mode { mode = normalized; return }
            UserDefaults.standard.set(mode, forKey: Self.key)
            // Commit before an immediate quit/relaunch, including during debugging.
            UserDefaults.standard.synchronize()
        }
    }

    private init() {
        mode = Self.normalized(UserDefaults.standard.string(forKey: Self.key) ?? "system")
    }

    private static func normalized(_ candidate: String) -> String {
        ["system", "light", "dark"].contains(candidate) ? candidate : "system"
    }

    var colorScheme: ColorScheme? {
        switch mode {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var appKitAppearance: NSAppearance? {
        switch mode {
        case "light": NSAppearance(named: .aqua)
        case "dark": NSAppearance(named: .darkAqua)
        default: nil
        }
    }
}

@main
struct LaterBoxMacApp: App {
    @NSApplicationDelegateAdaptor(LaterBoxMacDelegate.self) private var appDelegate
    @StateObject private var theme = MacAppearanceSettings.shared

    var body: some Scene {
        WindowGroup {
            MacLoginView()
                .preferredColorScheme(theme.colorScheme)
                .background(MacThemeWindowBridge(appearance: theme.mode).frame(width: 0, height: 0))
                .onChange(of: theme.mode, initial: true) { _, _ in
                    NSApp.appearance = theme.appKitAppearance
                }
                .frame(minWidth: 430, minHeight: 480)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 550, height: 620)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Quick Capture") { appDelegate.showQuickCapture() }
                    .keyboardShortcut("n", modifiers: [.command, .option])
            }
        }
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
    enum Step: Equatable { case restoring, email, password, signup, verify, authenticated }
    @Published var step: Step = .restoring
    @Published var email = ""
    @Published private(set) var accountEmail = ""
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
    private var sessionRevision = 0
    private var restoringSession = false
    private var refreshingSession = false

    var isValid: Bool {
        let validEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
        switch step {
        case .restoring: return false
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
        case .restoring: break
        case .email:
            email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            step = .password
        case .password: Task { await signIn() }
        case .signup: Task { await signUp() }
        case .verify: Task { await verify() }
        case .authenticated: break
        }
    }

    // Read previous credentials from the macOS Keychain before displaying auth.
    // Network outages never erase a user's session.
    func restoreSession() async {
        guard step == .restoring, !restoringSession else { return }
        restoringSession = true
        defer { restoringSession = false }
        let revision = sessionRevision
        do {
            guard let credentials = try readCredentials() else {
                if revision == sessionRevision { step = .email }
                return
            }

            if let token = credentials["access_token"] { updateAccountEmail(from: token) }

            // Prefer refresh if a refresh token is available, even if the old
            // access token looks valid. This also detects revoked sessions.
            if let refresh = credentials["refresh_token"], !refresh.isEmpty {
                do {
                    let data = try await post("/auth/v1/token?grant_type=refresh_token", body: [
                        "refresh_token": refresh
                    ])
                    guard revision == sessionRevision else { return }
                    try storeSession(data)
                    step = .authenticated
                    return
                } catch {
                    guard revision == sessionRevision else { return }
                    if isRejectedCredentials(error) {
                        clearSession()
                        step = .email
                        return
                    }
                    // Keep the native offline shell available with saved
                    // credentials even if the access token has expired.
                    step = .authenticated
                    info = "Offline. Your account will reconnect automatically."
                    return
                }
            }

            // Older sessions may lack refresh tokens. Only trust a valid,
            // nonexpired JWT, then require sign-in when it expires.
            if let token = credentials["access_token"], hasUnexpiredJWT(token) {
                guard revision == sessionRevision else { return }
                step = .authenticated
            } else if revision == sessionRevision {
                clearSession()
                step = .email
            }
        } catch {
            if revision == sessionRevision {
                step = .email
                self.error = "Could not access the saved macOS session."
            }
        }
    }

    // Called when returning to the foreground. Refreshes token rotation without
    // causing a sign-out on temporary connectivity failures.
    func refreshSessionIfNeeded() async {
        guard step == .authenticated, !restoringSession, !refreshingSession else { return }
        refreshingSession = true
        defer { refreshingSession = false }
        let revision = sessionRevision
        guard let credentials = try? readCredentials(),
              let refresh = credentials["refresh_token"], !refresh.isEmpty else { return }
        do {
            let data = try await post("/auth/v1/token?grant_type=refresh_token", body: [
                "refresh_token": refresh
            ])
            guard revision == sessionRevision else { return }
            try storeSession(data)
            info = nil
        } catch {
            guard revision == sessionRevision else { return }
            if isRejectedCredentials(error) {
                clearSession()
                step = .email
                self.error = "Your session expired. Please sign in again."
            }
        }
    }

    private func readCredentials() throws -> [String: String]? {
        var query = sessionQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        guard let data = result as? Data else { return nil }
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    private var sessionQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrAccount as String: "laterbox-macos-session"]
    }

    private func clearSession() {
        SecItemDelete(sessionQuery as CFDictionary)
    }

    private func isRejectedCredentials(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "LaterBoxAuth" && [400, 401, 403].contains(nsError.code)
    }

    // Resolve display initials from the authenticated JWT; supports restored
    // sessions and browser OAuth without requiring a separate profile API.
    private func updateAccountEmail(from token: String) {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return }
        var encoded = String(parts[1]).replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
        guard let data = Data(base64Encoded: encoded),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = payload["email"] as? String else { return }
        accountEmail = email
    }

    private func hasUnexpiredJWT(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return false }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let expiration = payload["exp"] as? TimeInterval else { return false }
        return expiration > Date().timeIntervalSince1970 + 30
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
        // Update in place so a failed write never destroys the old session.
        let updated = SecItemUpdate(sessionQuery as CFDictionary, [
            kSecValueData as String: value
        ] as CFDictionary)
        if updated == errSecSuccess {
            updateAccountEmail(from: access)
            if accountEmail.isEmpty { accountEmail = email }
            return
        }
        guard updated == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(updated),
                          userInfo: [NSLocalizedDescriptionKey: "Unable to update your saved session."])
        }
        var insert = sessionQuery
        insert[kSecValueData as String] = value
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                          userInfo: [NSLocalizedDescriptionKey: "Unable to save your sign-in securely."])
        }
        updateAccountEmail(from: access)
        if accountEmail.isEmpty { accountEmail = email }
    }

    func signOut() {
        sessionRevision += 1
        clearSession()
        accountEmail = ""
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
            window.standardWindowButton(type)?.isHidden = false
        }
    }
}


private struct MacAuthInput: View {
    enum Kind { case email, password, confirmation, code }
    let kind: Kind
    @Binding var value: String
    let submit: () -> Void
    var showsPassword: Binding<Bool>? = nil
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var symbol: String {
        switch kind {
        case .email: return "envelope"
        case .password, .confirmation: return "lock"
        case .code: return "number"
        }
    }

    private var placeholder: String {
        switch kind {
        case .email: return "Email address"
        case .password: return "Password"
        case .confirmation: return "Confirm password"
        case .code: return "8-digit code"
        }
    }

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(focused ? .primary : .secondary)
                .frame(width: 19)
                .accessibilityHidden(true)

            Group {
                if kind == .password || kind == .confirmation {
                    if showsPassword?.wrappedValue == true && kind == .password {
                        TextField(placeholder, text: $value)
                    } else {
                        SecureField(placeholder, text: $value)
                    }
                } else {
                    TextField(placeholder, text: $value)
                }
            }
            .font(.system(size: 14))
            .textContentType(kind == .email ? .emailAddress : (kind == .confirmation ? .newPassword : (kind == .password ? .password : .oneTimeCode)))
            .textFieldStyle(.plain)
            .focused($focused)
            .onSubmit(submit)
            .accessibilityIdentifier("mac.auth.\(kind == .email ? "email" : kind == .password ? "password" : kind == .confirmation ? "confirm" : "code")")

            if kind == .password, let showsPassword {
                Button { showsPassword.wrappedValue.toggle() } label: {
                    Image(systemName: showsPassword.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showsPassword.wrappedValue ? "Hide password" : "Show password")
            } else if kind == .email && !value.isEmpty {
                Button {
                    value = ""
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
            colorScheme == .dark ? Color(red: 41 / 255, green: 44 / 255, blue: 46 / 255) : Color.white,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    focused ? Color.primary.opacity(0.60) : (colorScheme == .dark ? Color.white.opacity(0.13) : Color(red: 220 / 255, green: 224 / 255, blue: 214 / 255)),
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
        case .restoring: return ""
        case .email, .password: return "Sign in"
        case .signup: return "Create account"
        case .verify: return "Verify email"
        case .authenticated: return "Signed in"
        }
    }

    var body: some View {
        Group {
            if auth.step == .authenticated {
                MacDashboardView(signOut: auth.signOut, accountEmail: auth.accountEmail)
            } else if auth.step == .restoring {
                ZStack {
                    MacAuthCanvas().ignoresSafeArea()
                    ProgressView().controlSize(.large)
                }
                .background(MacWindowChrome().frame(width: 0, height: 0))
            } else {
                ZStack(alignment: .topLeading) {
                    MacAuthCanvas().ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 18)
            VStack(spacing: 22) {
                Image(scheme == .dark ? "LaterboxLogoWhite" : "LaterboxLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 56)
                    .accessibilityLabel("LaterBox")

                Text(title)
                    .font(.system(size: 25, weight: .semibold))
                    .tracking(-0.6)

                if auth.step == .authenticated {
                    Button("Sign out", action: auth.signOut)
                        .buttonStyle(.bordered)
                } else {
                    VStack(spacing: 12) {
                        if auth.step == .email || auth.step == .signup {
                            MacAuthInput(kind: .email, value: $auth.email, submit: auth.submit)
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
                            MacAuthInput(kind: .password, value: $auth.password, submit: auth.submit, showsPassword: $auth.showPassword)
                        }

                        if auth.step == .signup {
                            MacAuthInput(kind: .confirmation, value: $auth.confirmPassword, submit: auth.submit)
                        }

                        if auth.step == .verify {
                            MacAuthInput(kind: .code, value: $auth.code, submit: auth.submit)
                                .onChange(of: auth.code) { _, next in
                                    auth.code = String(next.filter(\.isNumber).prefix(8))
                                }
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
        .background(Color.clear)

        }
                .background(MacWindowChrome().frame(width: 0, height: 0))
            }
        }
        .task { await auth.restoreSession() }
        .onChange(of: auth.step) { _, step in
            guard let window = NSApp.keyWindow else { return }
            let size = step == .authenticated ? NSSize(width: 1160, height: 800) : NSSize(width: 550, height: 620)
            window.setContentSize(size)
            window.center()
        }
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
        .background(scheme == .dark ? Color(red: 41 / 255, green: 44 / 255, blue: 46 / 255) : .white, in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(scheme == .dark ? Color.white.opacity(0.13) : Color(red: 220 / 255, green: 224 / 255, blue: 214 / 255)))
        .disabled(auth.busy)
    }
}

#Preview {
    MacLoginView().frame(width: 550, height: 620)
}
