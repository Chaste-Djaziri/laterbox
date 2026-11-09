//
//  AuthSheet.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public struct AuthSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var surface: Color { colorScheme == .dark ? Color(hex: "292C2E") : .white }
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color(hex: "DCE0D6")
    }
    @ObservedObject var coordinator = SyncCoordinator.shared

    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var step: AuthStep = .enterEmail
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    enum AuthStep {
        case enterEmail
        case verifyCode
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color(hex: "1B1D20") : Color(hex: "F8F9F5"))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    LaterBoxVectorMark(size: 62, appearance: .automatic, animates: false)
                        .frame(width: 76, height: 76)
                        .padding(.top, 12)
                        .accessibilityLabel("LaterBox")

                    VStack(spacing: 6) {
                        Text(step == .enterEmail ? "Sign In to LaterBox" : "Check Your Email")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)

                        Text(step == .enterEmail
                             ? "Enter your email to unlock multi-device cloud sync and Pro features."
                             : "We sent a 6-digit confirmation code to \(email).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    if let err = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if step == .enterEmail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                TextField("name@domain.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .padding(14)
                            .background(surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor, lineWidth: 1))
                        }

                        Button(action: sendCode) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Continue with Email")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(email.isEmpty || isLoading)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("6-Digit Verification Code")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            TextField("123456", text: $otpCode)
                                .keyboardType(.numberPad)
                                .font(.title3.weight(.bold).monospaced())
                                .padding(14)
                                .background(surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor, lineWidth: 1))
                        }

                        Button(action: verifyCode) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Verify & Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(otpCode.count < 6 || isLoading)

                        Button("Use a different email") {
                            step = .enterEmail
                            otpCode = ""
                            errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                }
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
                .padding(24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await LaterBoxAPIService.shared.sendEmailOTP(email: email.trimmingCharacters(in: .whitespaces))
                step = .verifyCode
                isLoading = false
                LBHaptic.success()
            } catch {
                errorMessage = "Could not send verification code. Please try again."
                isLoading = false
            }
        }
    }

    private func verifyCode() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (token, refreshToken, userId) = try await LaterBoxAPIService.shared.verifyOTP(email: email.trimmingCharacters(in: .whitespaces), token: otpCode.trimmingCharacters(in: .whitespaces))
                coordinator.setSession(email: email, userId: userId, token: token, refreshToken: refreshToken)
                isLoading = false
                dismiss()
            } catch {
                errorMessage = "Invalid verification code. Please check and try again."
                isLoading = false
            }
        }
    }
}
