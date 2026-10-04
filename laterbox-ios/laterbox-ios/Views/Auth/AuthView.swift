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
            LiquidGlassBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top Illustration / Hero
                    ZStack {
                        Circle()
                            .fill(Color.lbEmerald.opacity(0.15))
                            .blur(radius: 40)
                            .frame(width: 180, height: 180)

                        Image("AuthHero")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
                    }
                    .padding(.top, 10)

                    // Header Text
                    VStack(spacing: 8) {
                        Text(step == .enterEmail ? "Sign In to Laterbox" : "Check Your Email")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text(step == .enterEmail
                             ? "Enter your email to receive a passwordless 8-digit verification code."
                             : "We sent an 8-digit sign-in code to \(email).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Status / Error Notification Card
                    if let error = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.red.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    if let info = infoMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.lbEmerald)
                            Text(info)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.lbEmerald.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.lbEmerald.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // Input Form
                    VStack(spacing: 16) {
                        if step == .enterEmail {
                            // Email input field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    TextField("name@example.com", text: $email)
                                        .font(.body)
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
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(16)
                                .liquidGlassCard(cornerRadius: 16)

                                // Quick domain completion pill
                                if !email.isEmpty && !email.contains("@") {
                                    Button(action: {
                                        email = "\(email.trimmingCharacters(in: .whitespaces))@gmail.com"
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.caption2)
                                            Text("@gmail.com")
                                                .font(.caption.weight(.semibold))
                                        }
                                        .foregroundColor(.lbEmerald)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .liquidGlass(cornerRadius: 10)
                                    }
                                    .padding(.leading, 4)
                                }
                            }

                            // Submit Button
                            Button(action: submitEmail) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Continue with Email")
                                            .font(.headline.weight(.bold))
                                        Image(systemName: "arrow.right")
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.lbEmerald, Color.lbEmerald.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.lbEmerald.opacity(0.35), radius: 12, x: 0, y: 5)
                            }
                            .disabled(isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty)
                            .opacity((isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1.0)
                        } else {
                            // OTP 8-digit input field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    TextField("12345678", text: $otpCode)
                                        .font(.title3.weight(.bold).monospaced())
                                        .keyboardType(.numberPad)
                                        .autocorrectionDisabled()
                                        .onChange(of: otpCode) { _, newValue in
                                            // Limit to 8 digits
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
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(16)
                                .liquidGlassCard(cornerRadius: 16)
                            }

                            // Verify Button
                            Button(action: verifyCode) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Verify & Sign In")
                                            .font(.headline.weight(.bold))
                                        Image(systemName: "checkmark")
                                            .font(.headline.weight(.bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.lbEmerald, Color.lbEmerald.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.lbEmerald.opacity(0.35), radius: 12, x: 0, y: 5)
                            }
                            .disabled(isLoading || otpCode.count != 8)
                            .opacity((isLoading || otpCode.count != 8) ? 0.6 : 1.0)

                            // Alternative actions
                            HStack {
                                Button("Resend Code") {
                                    submitEmail()
                                }
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.lbEmerald)

                                Spacer()

                                Button("Use Different Email") {
                                    withAnimation {
                                        step = .enterEmail
                                        otpCode = ""
                                        errorMessage = nil
                                        infoMessage = nil
                                    }
                                }
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
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
                    infoMessage = "8-digit verification code sent!"
                    LBHaptic.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
    .preferredColorScheme(.dark)
}
