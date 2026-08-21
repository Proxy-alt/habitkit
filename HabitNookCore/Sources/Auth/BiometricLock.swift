import Foundation
import LocalAuthentication
import Security

// MARK: - BiometricLock

/// Provides per-habit biometric lock using LocalAuthentication and
/// Secure Enclave (§8.35).
///
/// When a habit is marked "sensitive", the user must authenticate with
/// Face ID / Touch ID before viewing its completions or logging it manually.
/// Authentication results are cached for the duration of the app session.
public actor BiometricLock {

    // MARK: - Shared instance

    public static let shared = BiometricLock()

    // MARK: - Private state

    /// Habits that have been authenticated in this app session.
    private var unlockedHabitIDs: Set<UUID> = []

    // MARK: - Init

    private init() {}

    // MARK: - Authentication

    /// Authenticates the user with biometrics to unlock a sensitive habit.
    ///
    /// If the habit has already been unlocked in this session, succeeds
    /// immediately without prompting.
    ///
    /// - Parameters:
    ///   - habitID: The habit to unlock.
    ///   - reason: Localised reason string shown in the biometric prompt.
    /// - Returns: `true` if authentication succeeded.
    public func authenticate(habitID: UUID, reason: String) async -> Bool {
        if unlockedHabitIDs.contains(habitID) { return true }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to device passcode if biometrics unavailable.
            return await authenticateWithPasscode(habitID: habitID, reason: reason)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                unlockedHabitIDs.insert(habitID)
            }
            return success
        } catch {
            return false
        }
    }

    /// Locks a habit, requiring re-authentication on the next access.
    ///
    /// - Parameter habitID: The habit to lock.
    public func lock(habitID: UUID) {
        unlockedHabitIDs.remove(habitID)
    }

    /// Locks all habits (e.g. on app backgrounding).
    public func lockAll() {
        unlockedHabitIDs.removeAll()
    }

    /// Returns whether a specific habit is currently unlocked.
    ///
    /// - Parameter habitID: The habit to check.
    public func isUnlocked(habitID: UUID) -> Bool {
        unlockedHabitIDs.contains(habitID)
    }

    // MARK: - Private

    private func authenticateWithPasscode(habitID: UUID, reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success {
                unlockedHabitIDs.insert(habitID)
            }
            return success
        } catch {
            return false
        }
    }
}
