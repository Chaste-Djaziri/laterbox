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

    enum AuthStep {
        case enterEmail
        case verifyOTP
    }

    @State private var step: AuthStep = .enterEmail
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil

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
                    Text(step == .enterEmail ? "Enter your email" : "Enter the code")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)

                    // Subtitle
                    Text(step == .enterEmail
                         ? "We'll send you a code to sign in or create your account."
                         : "We sent an 8-digit code to \(email).")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)

                    // Text Input Field
                    if step == .enterEmail {
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
                    } else {
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

                    // Primary Black "Continue" Button
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

                    // Secondary Action: "Continue without account"
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
                    } else {
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
                let (token, userId) = try await LaterBoxAPIService.shared.verifyOTP(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    token: cleanToken
                )

                await MainActor.run {
                    isLoading = false
                    coordinator.setSession(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        userId: userId,
                        token: token
                    )
                    dismiss()
                }

                // Trigger background sync for items
                await coordinator.syncPendingItems(context: modelContext)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid verification code. Please check your email and try again."
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
