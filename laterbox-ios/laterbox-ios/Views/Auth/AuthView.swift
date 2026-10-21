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

    @State private var step: AuthStep = .enterEmail
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var isFetchingMailpit: Bool = false
    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil

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

    var body: some View {
        ZStack {
            // #F7F5EE Background
            Color.lbBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {
                    // Laterbox Logo (centered)
                    Image("LaterboxLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 88)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 36)
                        .padding(.bottom, 28)

                    // Title
                    Text(headerTitle)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)

                    // Subtitle
                    Text(headerSubtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)

                    // Input or Action Area
                    switch step {
                    case .enterEmail:
                        HStack {
                            Spacer(minLength: !email.isEmpty ? 24 : 0)
                            TextField("Email", text: $email)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
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
                                        .foregroundColor(Color.black.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )

                        #if DEBUG
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("Dev Mode · Target: \(LaterBoxAPIService.shared.supabaseUrl)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        .padding(.top, 8)
                        #endif

                    case .enterPassword(let isSignUp):
                        HStack {
                            Spacer(minLength: 24)
                            if showPassword {
                                TextField("Password (min 6 characters)", text: $password)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .submitLabel(.continue)
                                    .onSubmit {
                                        submitPassword(isSignUp: isSignUp)
                                    }
                            } else {
                                SecureField("Password (min 6 characters)", text: $password)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
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
                                    .foregroundColor(Color.black.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )

                    case .verifyOTP:
                        HStack {
                            Spacer(minLength: !otpCode.isEmpty ? 24 : 0)
                            TextField("8-digit code", text: $otpCode)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
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
                                        .foregroundColor(Color.black.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )

                        #if DEBUG
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.badge.shield.half.filled")
                                    .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                                Text("Dev Mode · Local Mailpit")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            HStack(spacing: 12) {
                                Button(action: { fetchMailpitCode() }) {
                                    HStack(spacing: 6) {
                                        if isFetchingMailpit {
                                            ProgressView().scaleEffect(0.7)
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
                                    .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 1))
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
                                        .foregroundColor(.black.opacity(0.8))
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        #endif

                    case .resolveLocalData(let count, let token, let refreshToken, let userId):
                        VStack(spacing: 16) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 26/255, green: 26/255, blue: 26/255).opacity(0.08))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(count) Local Item\(count == 1 ? "" : "s")")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.black)
                                    Text("Merge them with your account or discard them to download your cloud catalog.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color.black.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )

                            // Option 1: Merge Local Items (Primary)
                            Button(action: {
                                resolveData(merge: true, token: token, refreshToken: refreshToken, userId: userId)
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Merge with Account")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(isLoading)

                            // Option 2: Remove Local Items
                            Button(action: {
                                resolveData(merge: false, token: token, refreshToken: refreshToken, userId: userId)
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Remove Local Data")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(Color.red.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(isLoading)
                        }
                    }

                    // Error / Info feedback
                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    } else if let info = infoMessage {
                        Text(info)
                            .font(.footnote)
                            .foregroundColor(Color.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }

                    // Primary Black Action Button for Email, Password, and OTP steps
                    if step != .resolveLocalData(unassignedCount: 0, token: "", refreshToken: nil, userId: "") && !isResolveStep {
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
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(continueButtonTitle)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isButtonDisabled)
                        .opacity(isButtonDisabled ? 0.6 : 1.0)
                        .padding(.top, 18)
                    }

                    if step == .enterEmail {
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                            Text("OR").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                        }
                        .padding(.top, 10)

                        SignInWithAppleButton(.signIn, onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        }, onCompletion: handleAppleResult)
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .disabled(isLoading)
                    }

                    // Secondary Actions
                    if step == .enterEmail {
                        Button(action: {
                            LBHaptic.light()
                            coordinator.continueAsGuest()
                            dismiss()
                        }) {
                            Text("Continue without account")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color.black.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
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
                        .foregroundColor(Color.black.opacity(0.75))
                        .padding(.top, 16)
                    } else if case .verifyOTP(let type) = step {
                        HStack(spacing: 20) {
                            Button("Resend code") {
                                if type == "signup" && !password.isEmpty {
                                    submitPassword(isSignUp: true)
                                } else {
                                    submitEmail()
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.75))

                            Text("•")
                                .foregroundColor(Color.black.opacity(0.3))

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
                            .foregroundColor(Color.black.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
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
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
    }

    private var isResolveStep: Bool {
        if case .resolveLocalData = step { return true }
        return false
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
                        #if DEBUG
                        fetchMailpitCode()
                        #endif
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
                        errorMessage = "Request timed out connecting to local backend at \(LaterBoxAPIService.shared.supabaseUrl). Ensure your iPhone is on the same network as your Mac (\(LaterBoxDevConfig.localHost))."
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
                            #if DEBUG
                            fetchMailpitCode()
                            #endif
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
            // Give local Mailpit a short moment to receive the message from local GoTrue
            try? await Task.sleep(nanoseconds: 700_000_000)
            if let code = await LaterBoxAPIService.shared.fetchLatestMailpitOTP(for: email) {
                await MainActor.run {
                    self.otpCode = code
                    self.isFetchingMailpit = false
                    LBHaptic.success()
                    if case .verifyOTP(let type) = step {
                        verifyCode(type: type)
                    }
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

#Preview {
    NavigationStack {
        AuthView()
    }
}
