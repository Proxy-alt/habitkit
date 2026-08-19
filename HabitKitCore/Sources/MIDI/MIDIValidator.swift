import CoreMIDI
import Foundation

// MARK: - MIDIValidator

/// Uses CoreMIDI to detect MIDI input during an instrument-practice habit (§8.38).
///
/// When a user starts a practice session, the validator opens a MIDI client and
/// listens for note-on events. Receiving enough notes within the session duration
/// confirms that the user is actively playing their instrument, enabling
/// auto-completion.
public actor MIDIValidator {

    // MARK: - Shared instance

    public static let shared = MIDIValidator()

    // MARK: - Private state

    private var midiClient = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var noteCount = 0
    private var isListening = false

    /// Minimum number of distinct note-on events to count as a valid session.
    private static let minimumNoteCount = 10

    // MARK: - Init

    private init() {}

    // MARK: - Session management

    /// Starts a MIDI validation session.
    ///
    /// Resets the note counter and opens a MIDI input port.
    ///
    /// - Parameter onValidated: Called once the minimum note count is reached.
    public func startSession(onValidated: @Sendable @escaping () -> Void) {
        noteCount = 0
        isListening = true

        let clientName = "HabitKit MIDI Validator" as CFString
        MIDIClientCreate(clientName, nil, nil, &midiClient)

        let portName = "HabitKit Input" as CFString
        MIDIInputPortCreateWithProtocol(midiClient, portName, ._1_0, &inputPort) {
            [weak self] eventList, srcConnRefCon in
            guard let self else { return }
            // The event list pointer is only valid for the duration of this
            // callback, so count note-on events synchronously here and send
            // only the (Sendable) count across to the actor.
            let noteOnCount = MIDIValidator.countNoteOnEvents(in: eventList)
            guard noteOnCount > 0 else { return }
            Task {
                await self.handleNoteOnEvents(count: noteOnCount, onValidated: onValidated)
            }
        }

        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)
        }
    }

    /// Stops the current MIDI validation session and releases resources.
    public func stopSession() {
        isListening = false
        MIDIPortDispose(inputPort)
        MIDIClientDispose(midiClient)
        noteCount = 0
    }

    /// Returns the number of note-on events received in the current session.
    public var currentNoteCount: Int { noteCount }

    // MARK: - Private

    /// Counts note-on events (status 0x90–0x9F, velocity > 0) in a MIDI event
    /// list. Runs synchronously on the MIDI callback thread, since the
    /// pointer is only valid for the duration of the callback.
    private static func countNoteOnEvents(in eventList: UnsafePointer<MIDIEventList>) -> Int {
        var count = 0
        var packet = eventList.pointee.packet
        for _ in 0..<eventList.pointee.numPackets {
            let bytes = Mirror(reflecting: packet.words).children
                .compactMap { $0.value as? UInt32 }
            for word in bytes {
                let status = UInt8((word >> 16) & 0xFF)
                let velocity = UInt8(word & 0xFF)
                if (status & 0xF0) == 0x90, velocity > 0 {
                    count += 1
                }
            }
            packet = MIDIEventPacketNext(&packet).pointee
        }
        return count
    }

    private func handleNoteOnEvents(
        count: Int,
        onValidated: @Sendable @escaping () -> Void
    ) {
        guard isListening else { return }
        noteCount += count
        if noteCount >= Self.minimumNoteCount {
            isListening = false
            onValidated()
        }
    }
}
