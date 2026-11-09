//
//  AuthView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var coordinator = SyncCoordinator.shared

    enum AuthStep: Equatable {
        case enterEmail
        case enterPassword(isSignUp: Bool)
        case verifyOTP(type: String)
        case resolveLocalData(unassignedCount: Int, token: String, refreshToken: String?, userId: String)
    }

    private enum LegalDocument: String, Identifiable {
        case terms
        case privacy

        var id: String { rawValue }

        var url: URL {
            switch self {
            case .terms:
                return URL(string: "\(LaterBoxAPIService.shared.webUrl)/terms")!
            case .privacy:
                return URL(string: "\(LaterBoxAPIService.shared.webUrl)/privacy")!
            }
        }
    }

    @State private var step: AuthStep = .enterEmail
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var isFetchingMailpit: Bool = false
    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil
    @State private var activeLegalDocument: LegalDocument? = nil
    @State private var openedFromActiveLibrary = false

    private let isPreviewSimulatorEnabled: Bool

    init(
        initialStep: AuthStep = .enterEmail,
        initialEmail: String = "",
        initialPassword: String = "",
        initialOtp: String = "",
        showSimulator: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    ) {
        _step = State(initialValue: initialStep)
        _email = State(initialValue: initialEmail)
        _password = State(initialValue: initialPassword)
        _otpCode = State(initialValue: initialOtp)
        self.isPreviewSimulatorEnabled = showSimulator
    }

    private var headerTitle: String {
        switch step {
        case .enterEmail:
            return "Enter your email"
        case .enterPassword(let isSignUp):
            return isSignUp ? "Create a password" : "Enter your password"
        case .verifyOTP:
            return "Enter the code"
        case .resolveLocalData:
            return "Sync local data"
        }
    }

    private var headerSubtitle: String {
        switch step {
        case .enterEmail:
            return "We'll send you a code to sign in or create your account."
        case .enterPassword(let isSignUp):
            return isSignUp
                ? "No account found for \(email). Create a password before we send your verification code."
                : "Enter the password for \(email)."
        case .verifyOTP:
            return "We sent an 8-digit code to \(email)."
        case .resolveLocalData(let count, _, _, _):
            return "You have \(count) item\(count == 1 ? "" : "s") saved on this device. Choose how to sync."
        }
    }

    private var isButtonDisabled: Bool {
        if isLoading { return true }
        switch step {
        case .enterEmail:
            return email.trimmingCharacters(in: .whitespaces).isEmpty
        case .enterPassword:
            return password.count < 6
        case .verifyOTP:
            return otpCode.count != 8
        case .resolveLocalData:
            return false
        }
    }

    private var continueButtonTitle: String {
        switch step {
        case .enterEmail:
            return "Continue"
        case .enterPassword(let isSignUp):
            return isSignUp ? "Continue & Send Code" : "Sign In"
        case .verifyOTP:
            return "Continue"
        case .resolveLocalData:
            return "Continue"
        }
    }

    private var isResolveStep: Bool {
        if case .resolveLocalData = step { return true }
        return false
    }

    // Neutral solid surfaces: keep authentication readable in both themes.
    private var canvas: Color {
        colorScheme == .dark ? Color(hex: "1B1D20") : Color(hex: "F8F9F5")
    }
    private var fieldSurface: Color {
        colorScheme == .dark ? Color(hex: "292C2E") : .white
    }
    private var primaryText: Color {
        colorScheme == .dark ? Color(hex: "F5F5F0") : Color(hex: "171711")
    }
    private var secondaryText: Color {
        colorScheme == .dark ? Color(hex: "ABB2AC") : Color(hex: "63685E")
    }
    private var subtleBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color(hex: "DCE0D6")
    }

    var body: some View {
        ZStack {
            canvas.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 10) {
                            LaterBoxVectorMark(size: 42, appearance: .automatic, animates: false)
                                .frame(width: 42, height: 42)
                                .accessibilityHidden(true)
                            Text("laterbox")
                                .font(.system(size: 22, weight: .bold))
                                .tracking(-0.8)
                                .foregroundStyle(primaryText)
                                .accessibilityLabel("LaterBox")
                            Spacer()
                            Button(action: handleNavigationBack) {
                                Image(systemName: step == .enterEmail ? "xmark" : "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(fieldSurface, in: Circle())
                                    .overlay(Circle().strokeBorder(subtleBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(step == .enterEmail ? "Close sign in" : "Back")
                        }

                        Spacer(minLength: 58)

                        VStack(alignment: .leading, spacing: 7) {
                            Text(headerTitle)
                                // Match the Welcome screen's San Francisco heading.
                                .font(.system(size: 38, weight: .bold))
                                .lineSpacing(-3)
                                .foregroundStyle(primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(headerSubtitle)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                        .padding(.bottom, 28)

                        #if DEBUG
                        if isPreviewSimulatorEnabled {
                            Menu {
                                Button("Email") { step = .enterEmail }
                                Button("Create password") {
                                    if email.isEmpty { email = "alex@example.com" }
                                    step = .enterPassword(isSignUp: true)
                                }
                                Button("Sign in with password") {
                                    if email.isEmpty { email = "alex@example.com" }
                                    step = .enterPassword(isSignUp: false)
                                }
                                Button("Verify email code") {
                                    if email.isEmpty { email = "alex@example.com" }
                                    step = .verifyOTP(type: "signup")
                                }
                                Button("Sync local data") {
                                    step = .resolveLocalData(
                                        unassignedCount: 4,
                                        token: "mock", refreshToken: "mock", userId: "mock"
                                    )
                                }
                            } label: {
                                Label("Preview authentication step", systemImage: "slider.horizontal.3")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(secondaryText)
                            }
                            .padding(.bottom, 18)
                        }
                        #endif

                        switch step {
                        case .enterEmail:
                            fieldLabel("Email address")
                            inputSurface {
                                Image(systemName: "envelope")
                                    .foregroundStyle(secondaryText)
                                TextField("", text: $email, prompt: Text("you@example.com").foregroundColor(secondaryText))
                                    .font(.system(size: 16))
                                    .foregroundStyle(primaryText)
                                    .tint(primaryText)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.continue)
                                    .onSubmit(submitEmail)
                                    .accessibilityIdentifier("auth.emailField")
                                if !email.isEmpty {
                                    Button { email = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(secondaryText)
                                    }
                                    .accessibilityLabel("Clear email")
                                }
                            }

                        case .enterPassword(let isSignUp):
                            fieldLabel("Password")
                            inputSurface {
                                Image(systemName: "lock")
                                    .foregroundStyle(secondaryText)
                                Group {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("At least 6 characters").foregroundColor(secondaryText))
                                    } else {
                                        SecureField("", text: $password, prompt: Text("At least 6 characters").foregroundColor(secondaryText))
                                    }
                                }
                                .font(.system(size: 16))
                                .foregroundStyle(primaryText)
                                .tint(primaryText)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.go)
                                .onSubmit { submitPassword(isSignUp: isSignUp) }
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(secondaryText)
                                }
                                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            }

                        case .verifyOTP:
                            fieldLabel("Verification code")
                            inputSurface {
                                Image(systemName: "number")
                                    .foregroundStyle(secondaryText)
                                TextField("", text: $otpCode, prompt: Text("8-digit code").foregroundColor(secondaryText))
                                    .font(.system(size: 21, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(primaryText)
                                    .tint(primaryText)
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                    .onChange(of: otpCode) { _, next in
                                        otpCode = String(next.filter { $0.isNumber }.prefix(8))
                                        if otpCode.count == 8, case .verifyOTP(let type) = step {
                                            verifyCode(type: type)
                                        }
                                    }
                                if !otpCode.isEmpty {
                                    Button { otpCode = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(secondaryText)
                                    }
                                    .accessibilityLabel("Clear code")
                                }
                            }

                            #if DEBUG
                            if isPreviewSimulatorEnabled && !LaterBoxAPIService.shared.mailpitUrl.isEmpty {
                                Button("Fetch test code from Mailpit") { fetchMailpitCode() }
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(secondaryText)
                                    .disabled(isFetchingMailpit)
                                    .padding(.top, 10)
                            }
                            #endif

                        case .resolveLocalData(let count, let token, let refreshToken, let userId):
                            HStack(spacing: 14) {
                                Image(systemName: "arrow.triangle.2.circlepath.icloud")
                                    .font(.system(size: 23))
                                    .foregroundStyle(Color(hex: "171711"))
                                    .frame(width: 52, height: 52)
                                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 15))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(count) local item\(count == 1 ? "" : "s")")
                                        .font(.headline)
                                        .foregroundStyle(primaryText)
                                    Text("Merge them with your cloud account, or remove the local copies.")
                                        .font(.subheadline)
                                        .foregroundStyle(secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(fieldSurface, in: RoundedRectangle(cornerRadius: 17))
                            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(subtleBorder, lineWidth: 1))

                            Button {
                                resolveData(merge: true, token: token, refreshToken: refreshToken, userId: userId)
                            } label: {
                                HStack(spacing: 9) {
                                    if isLoading {
                                        ProgressView().tint(Color(hex: "171711"))
                                    } else {
                                        Image(systemName: "arrow.triangle.merge")
                                        Text("Merge with account")
                                    }
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "171711"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 15))
                            }
                            .disabled(isLoading)
                            .padding(.top, 18)

                            Button {
                                resolveData(merge: false, token: token, refreshToken: refreshToken, userId: userId)
                            } label: {
                                Label("Remove local data", systemImage: "trash")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                            }
                            .disabled(isLoading)
                            .padding(.top, 10)
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(Color.red)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 12)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else if let infoMessage {
                            Text(infoMessage)
                                .font(.footnote)
                                .foregroundStyle(secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 12)
                        }

                        if !isResolveStep {
                            Button {
                                switch step {
                                case .enterEmail: submitEmail()
                                case .enterPassword(let isSignUp): submitPassword(isSignUp: isSignUp)
                                case .verifyOTP(let type): verifyCode(type: type)
                                case .resolveLocalData: break
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView().tint(Color(hex: "171711"))
                                    } else {
                                        Text(continueButtonTitle)
                                    }
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "171711"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 15))
                            }
                            .buttonStyle(.plain)
                            .disabled(isButtonDisabled)
                            .opacity(isButtonDisabled ? 0.52 : 1)
                            .padding(.top, 17)
                        }

                        if step == .enterEmail {
                            HStack(spacing: 14) {
                                Rectangle().fill(subtleBorder).frame(height: 1)
                                Text("or")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(secondaryText)
                                Rectangle().fill(subtleBorder).frame(height: 1)
                            }
                            .padding(.vertical, 21)

                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            }, onCompletion: handleAppleResult)
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            // Apple's native control enforces a 375pt maximum width.
                            // Expand the container, not the UIKit button, on wide phones/iPads.
                            .frame(maxWidth: 375)
                            .frame(height: 54)
                            // The native Apple control has its own smaller corner radius.
                            // Fill behind it with the same approved button color, then
                            // clip the complete shape to match Continue (15 pt).
                            .background(
                                colorScheme == .dark ? Color.white : Color.black,
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .frame(maxWidth: .infinity)
                            .disabled(isLoading)

                            Button {
                                LBHaptic.light()
                                coordinator.continueAsGuest()
                                dismiss()
                            } label: {
                                Text("Continue without account")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 22)
                            }
                            .buttonStyle(.plain)
                        } else if case .enterPassword = step {
                            Button("Use a different email") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    step = .enterEmail
                                    password = ""
                                    errorMessage = nil
                                    infoMessage = nil
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 18)
                        } else if case .verifyOTP(let type) = step {
                            HStack(spacing: 16) {
                                Button("Resend code") {
                                    if type == "signup" && !password.isEmpty {
                                        submitPassword(isSignUp: true)
                                    } else {
                                        submitEmail()
                                    }
                                }
                                Text("·").foregroundStyle(secondaryText)
                                Button("Use a different email") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        step = .enterEmail
                                        otpCode = ""
                                        password = ""
                                        errorMessage = nil
                                        infoMessage = nil
                                    }
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 18)
                        }

                        Spacer(minLength: 38)

                        VStack(spacing: 5) {
                            Text("By continuing, you agree to our")
                                .foregroundStyle(secondaryText)
                            HStack(spacing: 6) {
                                Button("Terms") { activeLegalDocument = .terms }
                                    .underline()
                                Text("and").foregroundStyle(secondaryText)
                                Button("Privacy Policy") { activeLegalDocument = .privacy }
                                    .underline()
                            }
                            .foregroundStyle(primaryText)
                            .buttonStyle(.plain)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: 440)
                    .frame(minHeight: max(0, geometry.size.height - 32), alignment: .top)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Welcome disappears when sign-in changes the root session.
            // Other callers present auth above an existing library.
            openedFromActiveLibrary = coordinator.hasAccess
        }
        .sheet(item: $activeLegalDocument) { document in
            SFSafariViewWrapper(url: document.url, entersReaderIfAvailable: false)
                .ignoresSafeArea()
        }
        // Follow the system color scheme. Do not override UIWindow appearance
        // from colorScheme callbacks: it causes a light/dark feedback loop
        // during navigation and can freeze the UI.
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(secondaryText)
            .padding(.bottom, 9)
    }

    private func inputSurface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            content()
        }
        .padding(.horizontal, 15)
        .frame(height: 56)
        .background(fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(subtleBorder, lineWidth: 1)
        }
    }

    private func finishSuccessfulAuthentication() {
        // Prevent duplicate navigation updates on login. ContentView owns
        // switching away from Welcome; only guest/library sheets need dismiss.
        if openedFromActiveLibrary {
            dismiss()
        }
    }

    private func handleNavigationBack() {
        switch step {
        case .enterEmail:
            dismiss()
        case .enterPassword:
            withAnimation {
                step = .enterEmail
                password = ""
                errorMessage = nil
                infoMessage = nil
            }
        case .verifyOTP:
            withAnimation {
                step = .enterEmail
                otpCode = ""
                errorMessage = nil
                infoMessage = nil
            }
        case .resolveLocalData:
            dismiss()
        }
    }

    // MARK: - Email Submission
    private func submitEmail() {
        var cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanEmail.contains("@") && !cleanEmail.isEmpty {
            cleanEmail = "\(cleanEmail)@gmail.com"
            email = cleanEmail
        }

        guard cleanEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            LBHaptic.error()
            return
        }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        LBHaptic.medium()

        Task {
            do {
                let result = try await LaterBoxAPIService.shared.requestEmailOTP(email: cleanEmail)
                await MainActor.run {
                    isLoading = false
                    switch result {
                    case .sent:
                        infoMessage = "Verification code sent to your email."
                        LBHaptic.success()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            step = .verifyOTP(type: "email")
                        }
                    case .userNotFound:
                        LBHaptic.light()
                        infoMessage = "Account not found. Create a password to get started."
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            step = .enterPassword(isSignUp: true)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    #if DEBUG
                    if let urlErr = error as? URLError, urlErr.code == .timedOut || urlErr.code == .cannotConnectToHost {
                        errorMessage = "Could not connect to LaterBox. Check your internet connection and try again."
                    } else {
                        errorMessage = "Failed to send code: \(error.localizedDescription)"
                    }
                    #else
                    errorMessage = "Failed to send code: \(error.localizedDescription)"
                    #endif
                    LBHaptic.error()
                }
            }
        }
    }

    // MARK: - Password Submission
    private func submitPassword(isSignUp: Bool) {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            LBHaptic.error()
            return
        }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        LBHaptic.medium()

        Task {
            do {
                if isSignUp {
                    let (requiresConfirmation, userId) = try await LaterBoxAPIService.shared.signUp(
                        email: cleanEmail,
                        password: password
                    )
                    await MainActor.run {
                        isLoading = false
                        LBHaptic.success()
                        if requiresConfirmation {
                            infoMessage = "Verification code sent to your email."
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                step = .verifyOTP(type: "signup")
                            }
                        } else if let userId {
                            finishAuth(token: "", refreshToken: nil, userId: userId)
                        }
                    }
                } else {
                    let (token, refreshToken, userId) = try await LaterBoxAPIService.shared.signInWithPassword(
                        email: cleanEmail,
                        password: password
                    )
                    await MainActor.run {
                        isLoading = false
                        LBHaptic.success()
                        finishAuth(token: token, refreshToken: refreshToken, userId: userId)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let desc = error.localizedDescription
                    if desc.localizedCaseInsensitiveContains("already registered") || desc.localizedCaseInsensitiveContains("already exists") {
                        errorMessage = "Account already exists for \(cleanEmail). Sign in with your password or use a code."
                    } else {
                        errorMessage = desc
                    }
                    LBHaptic.error()
                }
            }
        }
    }

    #if DEBUG
    private func fetchMailpitCode() {
        guard !isFetchingMailpit else { return }
        isFetchingMailpit = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let code = await LaterBoxAPIService.shared.fetchLatestMailpitOTP(for: email) {
                await MainActor.run {
                    self.otpCode = code
                    self.isFetchingMailpit = false
                    LBHaptic.success()
                }
            } else {
                await MainActor.run {
                    self.isFetchingMailpit = false
                }
            }
        }
    }
    #endif

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
            errorMessage = "Apple sign-in failed. Please try again."
            LBHaptic.error()
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Apple did not return a valid sign-in token."
                LBHaptic.error()
                return
            }
            signInWithApple(identityToken: identityToken, email: credential.email)
        }
    }

    private func signInWithApple(identityToken: String, email: String?) {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        LBHaptic.medium()
        Task {
            do {
                let result = try await LaterBoxAPIService.shared.signInWithApple(identityToken: identityToken)
                let accountEmail = email ?? result.email ?? "Apple account"
                try await coordinator.resolveLoginData(
                    merge: true,
                    email: accountEmail,
                    userId: result.userId,
                    token: result.accessToken,
                    refreshToken: result.refreshToken,
                    context: modelContext
                )
                await MainActor.run {
                    isLoading = false
                    LBHaptic.success()
                    finishSuccessfulAuthentication()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Could not sign in with Apple. Please try again."
                    LBHaptic.error()
                }
            }
        }
    }

    // MARK: - Code Verification
    private func verifyCode(type: String) {
        let cleanToken = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanToken.count == 8 else {
            errorMessage = "Please enter the complete 8-digit code."
            LBHaptic.error()
            return
        }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        LBHaptic.medium()

        Task {
            do {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let (token, refreshToken, userId) = try await LaterBoxAPIService.shared.verifyOTP(
                    email: cleanEmail,
                    token: cleanToken,
                    type: type
                )

                await MainActor.run {
                    isLoading = false
                    finishAuth(token: token, refreshToken: refreshToken, userId: userId)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid verification code. Please check your email and try again."
                    LBHaptic.error()
                }
            }
        }
    }

    private func finishAuth(token: String, refreshToken: String?, userId: String) {
        let unassignedCount = coordinator.countUnassignedLocalItems(context: modelContext, targetUserId: userId)
        if unassignedCount > 0 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                step = .resolveLocalData(
                    unassignedCount: unassignedCount,
                    token: token,
                    refreshToken: refreshToken,
                    userId: userId
                )
            }
        } else {
            Task {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    try await coordinator.resolveLoginData(
                        merge: true,
                        email: cleanEmail,
                        userId: userId,
                        token: token,
                        refreshToken: refreshToken,
                        context: modelContext
                    )
                    LBHaptic.success()
                    finishSuccessfulAuthentication()
                } catch {
                    errorMessage = "Could not complete sign-in: \(error.localizedDescription)"
                    LBHaptic.error()
                }
            }
        }
    }

    // MARK: - Local Data Resolution
    private func resolveData(merge: Bool, token: String, refreshToken: String?, userId: String) {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        LBHaptic.medium()

        Task {
            do {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                try await coordinator.resolveLoginData(
                    merge: merge,
                    email: cleanEmail,
                    userId: userId,
                    token: token,
                    refreshToken: refreshToken,
                    context: modelContext
                )
                await MainActor.run {
                    isLoading = false
                    LBHaptic.success()
                    finishSuccessfulAuthentication()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sync: \(error.localizedDescription)"
                    LBHaptic.error()
                }
            }
        }
    }
}

private struct AuthSimulatorPillStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
            .foregroundStyle(isSelected ? Color.black : Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.white : Color.white.opacity(0.16), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
    }
}

// MARK: - Previews for Every Auth State

#Preview("1. Enter Email") {
    NavigationStack {
        AuthView(initialStep: .enterEmail, showSimulator: true)
    }
}

#Preview("2. Create Password (Sign Up)") {
    NavigationStack {
        AuthView(
            initialStep: .enterPassword(isSignUp: true),
            initialEmail: "alex@example.com",
            showSimulator: true
        )
    }
}

#Preview("3. Enter Password (Sign In)") {
    NavigationStack {
        AuthView(
            initialStep: .enterPassword(isSignUp: false),
            initialEmail: "alex@example.com",
            showSimulator: true
        )
    }
}

#Preview("4. Verify OTP Code") {
    NavigationStack {
        AuthView(
            initialStep: .verifyOTP(type: "signup"),
            initialEmail: "alex@example.com",
            initialOtp: "48291055",
            showSimulator: true
        )
    }
}

#Preview("5. Sync Local Data") {
    NavigationStack {
        AuthView(
            initialStep: .resolveLocalData(
                unassignedCount: 4,
                token: "mock-token",
                refreshToken: "mock-refresh",
                userId: "mock-user"
            ),
            initialEmail: "alex@example.com",
            showSimulator: true
        )
    }
}
