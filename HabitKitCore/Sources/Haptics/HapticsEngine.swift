import CoreHaptics
import Foundation

// MARK: - HapticsEngine

/// Plays custom haptic patterns for habit completion events (§8.18).
///
/// Three named patterns are provided:
/// - **completion**: Celebratory burst for marking a habit done.
/// - **streak**: Ascending pattern for streak milestones.
/// - **warning**: Short double-tap for approaching-deadline reminder.
public actor HapticsEngine {

    // MARK: - Shared instance

    public static let shared = HapticsEngine()

    // MARK: - Private state

    private var engine: CHHapticEngine?

    // MARK: - Init

    private init() {}

    // MARK: - Setup

    /// Creates and starts the `CHHapticEngine` if haptics are supported.
    ///
    /// Call once at app launch or lazily before first playback.
    public func prepare() async throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let newEngine = try CHHapticEngine()
        newEngine.resetHandler = { [weak self] in
            Task { await self?.handleReset() }
        }
        newEngine.stoppedHandler = { _ in }
        try await newEngine.start()
        self.engine = newEngine
    }

    // MARK: - Playback

    /// Plays the completion haptic pattern.
    public func playCompletion() async {
        await play(pattern: completionPattern())
    }

    /// Plays the streak-milestone haptic pattern.
    public func playStreak() async {
        await play(pattern: streakPattern())
    }

    /// Plays the deadline-warning haptic pattern.
    public func playWarning() async {
        await play(pattern: warningPattern())
    }

    // MARK: - Private helpers

    private func play(pattern: CHHapticPattern?) {
        guard let engine, let pattern else { return }
        do {
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptic playback is best-effort; failures are silently discarded.
        }
    }

    private func handleReset() async {
        try? await engine?.start()
    }

    // MARK: - Pattern definitions

    private func completionPattern() -> CHHapticPattern? {
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                ],
                relativeTime: 0.1
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ],
                relativeTime: 0.2,
                duration: 0.3
            ),
        ]
        return try? CHHapticPattern(events: events, parameters: [])
    }

    private func streakPattern() -> CHHapticPattern? {
        let events: [CHHapticEvent] = (0..<3).map { i in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: 0.5 + Float(i) * 0.25
                    ),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
                ],
                relativeTime: TimeInterval(i) * 0.15
            )
        }
        return try? CHHapticPattern(events: events, parameters: [])
    }

    private func warningPattern() -> CHHapticPattern? {
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                ],
                relativeTime: 0.12
            ),
        ]
        return try? CHHapticPattern(events: events, parameters: [])
    }
}
