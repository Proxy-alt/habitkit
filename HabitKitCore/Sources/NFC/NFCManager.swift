import CoreNFC
import Foundation

// MARK: - NFCManager

/// Reads and writes NFC NDEF tags to encode habit deep links (§8.34).
///
/// A user can write a `habitkit://habit/<uuid>` URL to an NFC sticker.
/// Tapping the sticker while HabitKit is in the foreground logs the habit
/// instantly. Tapping when HabitKit is not running launches the app via
/// Universal Links.
public final class NFCManager: NSObject, NFCNDEFReaderSessionDelegate, Sendable {

    // MARK: - Shared instance

    public static let shared = NFCManager()

    // MARK: - Private state

    private var readSession: NFCNDEFReaderSession?
    private var writeSession: NFCNDEFReaderSession?

    /// Called when a habit tag is successfully read.
    public var onHabitTagRead: (@Sendable (UUID) -> Void)?

    /// Payload to write; set before starting a write session.
    private var pendingWritePayload: NFCNDEFMessage?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Reading

    /// Starts an NFC reading session.
    ///
    /// When a habitkit:// tag is detected, `onHabitTagRead` is called with
    /// the habit UUID.
    public func startReadingSession() {
        guard NFCNDEFReaderSession.readingAvailable else { return }
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: .main,
            invalidateAfterFirstRead: true
        )
        session.alertMessage = "Hold your iPhone near a HabitKit tag."
        readSession = session
        session.begin()
    }

    // MARK: - Writing

    /// Writes a habit deep link to the next tapped NFC tag.
    ///
    /// - Parameters:
    ///   - habitID: UUID of the habit to encode.
    ///   - habitName: Display name for the NDEF record title.
    public func writeHabitTag(habitID: UUID, habitName: String) {
        guard NFCNDEFReaderSession.readingAvailable else { return }
        let url = URL(string: "habitkit://habit/\(habitID.uuidString)")
        let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url ?? URL(string: "habitkit://")!)
        let message = NFCNDEFMessage(records: [uriPayload].compactMap { $0 })
        pendingWritePayload = message

        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: .main,
            invalidateAfterFirstRead: false
        )
        session.alertMessage = "Hold your iPhone near the tag to write \"\(habitName)\"."
        writeSession = session
        session.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    public func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: any Error
    ) {
        readSession = nil
        writeSession = nil
    }

    public func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        for message in messages {
            for record in message.records {
                guard let url = record.wellKnownTypeURIPayload() else { continue }
                if url.scheme == "habitkit",
                   url.host == "habit",
                   let idString = url.pathComponents.dropFirst().first,
                   let habitID = UUID(uuidString: idString) {
                    onHabitTagRead?(habitID)
                }
            }
        }
    }

    public func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetect tags: [any NFCNDEFTag]
    ) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard error == nil, let self else {
                session.invalidate(errorMessage: "Connection failed.")
                return
            }
            if let payload = self.pendingWritePayload {
                tag.writeNDEF(payload) { writeError in
                    if writeError == nil {
                        session.alertMessage = "Tag written successfully."
                    }
                    session.invalidate()
                }
            }
        }
    }
}
