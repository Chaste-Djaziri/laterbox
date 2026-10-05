//
//  AuthView.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var coordinator = SyncCoordinator.shared

    enum AuthStep: Equatable {
        case enterEmail
        case verifyOTP
        case resolveLocalData(unassignedCount: Int, token: String, userId: String)
    }

    @State private var step: AuthStep = .enterEmail
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil

    private var headerTitle: String {
        switch step {
        case .enterEmail: return "Enter your email"
        case .verifyOTP: return "Enter the code"
        case .resolveLocalData: return "Sync local data"
        }
    }

    private var headerSubtitle: String {
        switch step {
        case .enterEmail:
            return "We'll send you a code to sign in or create your account."
        case .verifyOTP:
            return "We sent an 8-digit code to \(email)."
        case .resolveLocalData(let count, _, _):
            return "You have \(count) item\(count == 1 ? "" : "s") saved on this device. Choose how to sync."
        }
    }

    var body: some View {
        ZStack {
            // #F7F5EE Background
            Color.lbBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {
                    // Laterbox Logo (significantly enlarged and centered)
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
                                        verifyCode()
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

                    case .resolveLocalData(let count, let token, let userId):
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
                                resolveData(merge: true, token: token, userId: userId)
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
                                resolveData(merge: false, token: token, userId: userId)
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

                    // Primary Black "Continue" Button for Email & OTP steps
                    if step == .enterEmail || step == .verifyOTP {
                        Button(action: {
                            if step == .enterEmail {
                                submitEmail()
                            } else {
                                verifyCode()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isLoading || (step == .enterEmail ? email.trimmingCharacters(in: .whitespaces).isEmpty : otpCode.count != 8))
                        .opacity((isLoading || (step == .enterEmail ? email.trimmingCharacters(in: .whitespaces).isEmpty : otpCode.count != 8)) ? 0.6 : 1.0)
                        .padding(.top, 18)
                    }

                    // Secondary Action: "Continue without account" or "Resend code"
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
                    } else if step == .verifyOTP {
                        HStack(spacing: 20) {
                            Button("Resend code") {
                                submitEmail()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.75))

                            Text("•")
                                .foregroundColor(Color.black.opacity(0.3))

                            Button("Use different email") {
                                withAnimation {
                                    step = .enterEmail
                                    otpCode = ""
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
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
                _ = try await LaterBoxAPIService.shared.sendEmailOTP(email: cleanEmail)
                await MainActor.run {
                    isLoading = false
                    infoMessage = "Verification code sent to your email."
                    LBHaptic.success()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step = .verifyOTP
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send code: \(error.localizedDescription)"
                    LBHaptic.error()
                }
            }
        }
    }

    // MARK: - Code Verification
    private func verifyCode() {
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
                let (token, userId) = try await LaterBoxAPIService.shared.verifyOTP(
                    email: cleanEmail,
                    token: cleanToken
                )

                let unassignedCount = await MainActor.run {
                    coordinator.countUnassignedLocalItems(context: modelContext, targetUserId: userId)
                }

                if unassignedCount > 0 {
                    await MainActor.run {
                        isLoading = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            step = .resolveLocalData(unassignedCount: unassignedCount, token: token, userId: userId)
                        }
                    }
                } else {
                    // No unassigned items; immediately hydrate catalog and finish
                    try await coordinator.resolveLoginData(
                        merge: true,
                        email: cleanEmail,
                        userId: userId,
                        token: token,
                        context: modelContext
                    )
                    await MainActor.run {
                        isLoading = false
                        LBHaptic.success()
                        dismiss()
                    }
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

    // MARK: - Local Data Resolution
    private func resolveData(merge: Bool, token: String, userId: String) {
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
