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
                return URL(string: "https://laterbox.dev/terms")!
            case .privacy:
                return URL(string: "https://laterbox.dev/privacy")!
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

    var body: some View {
        ZStack {
            // Same photographic canvas as Welcome: no visual jump after Sign In.
            GeometryReader { proxy in
                Image("WelcomeBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.62),
                    Color.black.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // All steps remain scrollable when the keyboard or Dynamic Type expands.
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Same white logo and glass control placement as Welcome.
                        HStack(alignment: .center) {
                            Image("LaterboxLogoWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 38)
                                .accessibilityLabel("LaterBox")

                            Spacer()

                            Button(action: handleNavigationBack) {
                                Image(systemName: step == .enterEmail ? "xmark" : "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.20), in: Circle())
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.40), lineWidth: 1))
                            }
                            .accessibilityLabel(step == .enterEmail ? "Close sign in" : "Back")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        Spacer(minLength: 40)

                        // Photo-backed, integrated bottom form: no detached card.
                        VStack(alignment: .leading, spacing: 0) {
                        // Title: Left-aligned
                        Text(headerTitle)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.82)
                            .shadow(color: .black.opacity(0.20), radius: 6, y: 2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 6)

                        // Subtitle: Left-aligned
                        Text(headerSubtitle)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white.opacity(0.87))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 16)

                        #if DEBUG
                        if isPreviewSimulatorEnabled {
                            // Dev Mode State Simulator: Quick Switcher for testing all authentication states (Only in Xcode Previews)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 7, height: 7)
                                    Text("Dev Simulator")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.82))
                                    Spacer()
                                    Text(LaterBoxAPIService.shared.supabaseUrl.replacingOccurrences(of: "http://", with: ""))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.82))
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        Button("Email") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                step = .enterEmail
                                                errorMessage = nil
                                                infoMessage = nil
                                            }
                                        }
                                        .buttonStyle(AuthSimulatorPillStyle(isSelected: step == .enterEmail))

                                        Button("Password (Sign Up)") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if email.isEmpty { email = "alex@example.com" }
                                                step = .enterPassword(isSignUp: true)
                                                errorMessage = nil
                                                infoMessage = nil
                                            }
                                        }
                                        .buttonStyle(AuthSimulatorPillStyle(isSelected: {
                                            if case .enterPassword(let isSignUp) = step { return isSignUp }
                                            return false
                                        }()))

                                        Button("Password (Sign In)") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if email.isEmpty { email = "alex@example.com" }
                                                step = .enterPassword(isSignUp: false)
                                                errorMessage = nil
                                                infoMessage = nil
                                            }
                                        }
                                        .buttonStyle(AuthSimulatorPillStyle(isSelected: {
                                            if case .enterPassword(let isSignUp) = step { return !isSignUp }
                                            return false
                                        }()))

                                        Button("Verify Code") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if email.isEmpty { email = "alex@example.com" }
                                                if otpCode.isEmpty { otpCode = "12345678" }
                                                step = .verifyOTP(type: "signup")
                                                errorMessage = nil
                                                infoMessage = nil
                                            }
                                        }
                                        .buttonStyle(AuthSimulatorPillStyle(isSelected: {
                                            if case .verifyOTP = step { return true }
                                            return false
                                        }()))

                                        Button("Sync Data") {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if email.isEmpty { email = "alex@example.com" }
                                                step = .resolveLocalData(unassignedCount: 4, token: "mock", refreshToken: "mock", userId: "mock")
                                                errorMessage = nil
                                                infoMessage = nil
                                            }
                                        }
                                        .buttonStyle(AuthSimulatorPillStyle(isSelected: {
                                            if case .resolveLocalData = step { return true }
                                            return false
                                        }()))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.20), lineWidth: 1))
                            .padding(.bottom, 16)
                        }
                        #endif

                        // Input or Action Area
                        switch step {
                        case .enterEmail:
                            HStack {
                                TextField(
                                    "",
                                    text: $email,
                                    prompt: Text("Email").foregroundColor(Color.black.opacity(0.50))
                                )
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .tint(.black)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.continue)
                                .onSubmit {
                                    submitEmail()
                                }

                                if !email.isEmpty {
                                    Button(action: { email = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.black.opacity(0.35))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .environment(\.colorScheme, .light)

                        case .enterPassword(let isSignUp):
                            HStack {
                                if showPassword {
                                    TextField(
                                        "",
                                        text: $password,
                                        prompt: Text("Password (min 6 characters)").foregroundColor(Color.black.opacity(0.50))
                                    )
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .tint(.black)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .submitLabel(.continue)
                                    .onSubmit {
                                        submitPassword(isSignUp: isSignUp)
                                    }
                                } else {
                                    SecureField(
                                        "",
                                        text: $password,
                                        prompt: Text("Password (min 6 characters)").foregroundColor(Color.black.opacity(0.50))
                                    )
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .tint(.black)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .submitLabel(.continue)
                                    .onSubmit {
                                        submitPassword(isSignUp: isSignUp)
                                    }
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.black.opacity(0.45))
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .environment(\.colorScheme, .light)

                        case .verifyOTP:
                            HStack {
                                Spacer(minLength: !otpCode.isEmpty ? 24 : 0)
                                TextField(
                                    "",
                                    text: $otpCode,
                                    prompt: Text("8-digit code").foregroundColor(Color.black.opacity(0.40))
                                )
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .tint(.black)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .onChange(of: otpCode) { _, newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 8 {
                                        otpCode = String(filtered.prefix(8))
                                    } else {
                                        otpCode = filtered
                                    }
                                    if otpCode.count == 8 {
                                        if case .verifyOTP(let type) = step {
                                            verifyCode(type: type)
                                        }
                                    }
                                }

                                if !otpCode.isEmpty {
                                    Button(action: { otpCode = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.black.opacity(0.35))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .environment(\.colorScheme, .light)

                            #if DEBUG
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "envelope.badge.shield.half.filled")
                                        .foregroundColor(.white)
                                    Text("Dev Mode · Local Mailpit")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.white.opacity(0.82))
                                }
                                HStack(spacing: 12) {
                                    Button(action: { fetchMailpitCode() }) {
                                        HStack(spacing: 6) {
                                            if isFetchingMailpit {
                                                ProgressView().scaleEffect(0.7).tint(.black)
                                            } else {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 11))
                                            }
                                            Text("Fetch from Mailpit")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                    }
                                    .disabled(isFetchingMailpit)

                                    if let mailpitUrl = URL(string: LaterBoxAPIService.shared.mailpitUrl) {
                                        Link(destination: mailpitUrl) {
                                            HStack(spacing: 4) {
                                                Text("Open Mailpit")
                                                    .font(.system(size: 13, weight: .medium))
                                                Image(systemName: "arrow.up.right")
                                                    .font(.system(size: 10))
                                            }
                                            .foregroundColor(Color.white.opacity(0.82))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                            #endif

                        case .resolveLocalData(let count, let token, let refreshToken, let userId):
                            VStack(spacing: 14) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.20))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(count) Local Item\(count == 1 ? "" : "s")")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Merge them with your account or discard them to download your cloud catalog.")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Color.white.opacity(0.82))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 1))

                                Button(action: {
                                    resolveData(merge: true, token: token, refreshToken: refreshToken, userId: userId)
                                }) {
                                    HStack {
                                        if isLoading {
                                            ProgressView().tint(.black)
                                        } else {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Merge with Account")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(isLoading)

                                Button(action: {
                                    resolveData(merge: false, token: token, refreshToken: refreshToken, userId: userId)
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 15, weight: .medium))
                                        Text("Remove Local Data")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(Color(red: 1, green: 0.68, blue: 0.65))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.red.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(isLoading)
                            }
                        }

                        // Feedback Messages: Left-aligned
                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Color(red: 1, green: 0.72, blue: 0.69))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        } else if let info = infoMessage {
                            Text(info)
                                .font(.footnote)
                                .foregroundColor(Color.white.opacity(0.82))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }

                        // Primary Action Button
                        if !isResolveStep {
                            Button(action: {
                                switch step {
                                case .enterEmail:
                                    submitEmail()
                                case .enterPassword(let isSignUp):
                                    submitPassword(isSignUp: isSignUp)
                                case .verifyOTP(let type):
                                    verifyCode(type: type)
                                case .resolveLocalData:
                                    break
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.black)
                                    } else {
                                        Text(continueButtonTitle)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(isButtonDisabled)
                            .opacity(isButtonDisabled ? 0.5 : 1.0)
                            .padding(.top, 16)
                        }

                        // Apple OAuth for Email Step
                        if step == .enterEmail {
                            HStack(spacing: 12) {
                                Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
                                Text("OR").font(.caption.weight(.semibold)).foregroundStyle(Color.white.opacity(0.80))
                                Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 14)

                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            }, onCompletion: handleAppleResult)
                            .signInWithAppleButtonStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
                            .disabled(isLoading)
                        }

                        // Secondary Options
                        if step == .enterEmail {
                            Button(action: {
                                LBHaptic.light()
                                coordinator.continueAsGuest()
                                dismiss()
                            }) {
                                Text("Continue without account")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 16)
                            }
                        } else if case .enterPassword = step {
                            Button("Use different email") {
                                withAnimation {
                                    step = .enterEmail
                                    password = ""
                                    errorMessage = nil
                                    infoMessage = nil
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 16)
                        } else if case .verifyOTP(let type) = step {
                            HStack(spacing: 16) {
                                Button("Resend code") {
                                    if type == "signup" && !password.isEmpty {
                                        submitPassword(isSignUp: true)
                                    } else {
                                        submitEmail()
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.82))

                                Text("•")
                                    .foregroundColor(Color.white.opacity(0.48))

                                Button("Use different email") {
                                    withAnimation {
                                        step = .enterEmail
                                        otpCode = ""
                                        password = ""
                                        errorMessage = nil
                                        infoMessage = nil
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.82))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 16)
                        }

                        // Legal Disclaimer
                        VStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .foregroundStyle(Color.white.opacity(0.73))
                            HStack(spacing: 5) {
                                Button("Terms") { activeLegalDocument = .terms }
                                    .underline()
                                Text("and")
                                    .foregroundStyle(Color.white.opacity(0.73))
                                Button("Privacy Policy") { activeLegalDocument = .privacy }
                                    .underline()
                            }
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .whiteStatusBar()
        .sheet(item: $activeLegalDocument) { doc in
            SFSafariViewWrapper(url: doc.url, entersReaderIfAvailable: false)
                .ignoresSafeArea()
        }
        .onDisappear {
            StatusBarStyleModifier.apply(coordinator.hasAccess ? .light : .dark)
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
                    dismiss()
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
                try? await coordinator.resolveLoginData(
                    merge: true,
                    email: cleanEmail,
                    userId: userId,
                    token: token,
                    refreshToken: refreshToken,
                    context: modelContext
                )
                await MainActor.run {
                    LBHaptic.success()
                    dismiss()
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
                    dismiss()
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
