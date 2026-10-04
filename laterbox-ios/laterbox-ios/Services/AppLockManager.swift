//
//  AppLockManager.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 05.10.26.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine

@MainActor
public final class AppLockManager: ObservableObject {
    public static let shared = AppLockManager()

    private let defaults = UserDefaults.standard
    private let appLockKey = "lb_biometric_app_lock_enabled"

    // MARK: - Published State
    @Published public var isAppLockEnabled: Bool {
        didSet {
            defaults.set(isAppLockEnabled, forKey: appLockKey)
        }
    }

    @Published public var isLocked: Bool = false
    @Published public var biometryType: LABiometryType = .none
    @Published public var isAuthenticating: Bool = false
    @Published public var authenticationError: String? = nil

    private init() {
        let savedState = UserDefaults.standard.bool(forKey: appLockKey)
        self.isAppLockEnabled = savedState
        // If enabled on startup, lock immediately
        self.isLocked = savedState
        refreshBiometryType()
    }

    // MARK: - Biometry Detection
    public func refreshBiometryType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometryType = context.biometryType
        } else {
            self.biometryType = .none
        }
    }

    public var biometryName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Passcode"
        }
    }

    public var biometryIconName: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.fill"
        }
    }

    // MARK: - Toggle Actions
    public func toggleAppLock() async -> Bool {
        if isAppLockEnabled {
            return await disableAppLock()
        } else {
            return await enableAppLock()
        }
    }

    public func enableAppLock() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        authenticationError = nil
        isAuthenticating = true

        let reason = "Confirm identity to enable \(biometryName) lock for LaterBox."

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            isAuthenticating = false
            if success {
                self.isAppLockEnabled = true
                LBHaptic.success()
                return true
            } else {
                return false
            }
        } catch {
            isAuthenticating = false
            self.authenticationError = error.localizedDescription
            LBHaptic.error()
            return false
        }
    }

    public func disableAppLock() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        authenticationError = nil
        isAuthenticating = true

        let reason = "Confirm identity to turn off App Lock."

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            isAuthenticating = false
            if success {
                self.isAppLockEnabled = false
                self.isLocked = false
                LBHaptic.light()
                return true
            } else {
                return false
            }
        } catch {
            isAuthenticating = false
            self.authenticationError = error.localizedDescription
            LBHaptic.error()
            return false
        }
    }

    // MARK: - Unlock Application
    public func unlockApp() async -> Bool {
        guard isLocked else { return true }
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        authenticationError = nil
        isAuthenticating = true

        let reason = "Unlock LaterBox to access your private saves and notes."

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            isAuthenticating = false
            if success {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    self.isLocked = false
                }
                LBHaptic.success()
                return true
            } else {
                return false
            }
        } catch {
            isAuthenticating = false
            self.authenticationError = error.localizedDescription
            LBHaptic.error()
            return false
        }
    }

    // MARK: - Lifecycle Handlers
    public func lockAppIfNeeded() {
        if isAppLockEnabled {
            self.isLocked = true
        }
    }
}
