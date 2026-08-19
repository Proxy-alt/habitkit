import Foundation
import MultipeerConnectivity

// MARK: - MultipeerSession

/// Manages MCSession-based peer-to-peer communication for habit template
/// trading and syncing live timer state between nearby devices (§8.30).
///
/// HabitKit advertises itself as "habitkit-share" and discovers peers with
/// the same service type. Template data is sent as JSON; live timer ticks
/// are sent as small binary payloads.
public final class MultipeerSession: NSObject, @unchecked Sendable {

    // MARK: - Shared instance

    public static let shared = MultipeerSession()

    // MARK: - Constants

    private static let serviceType = "habitkit-share"

    // MARK: - Private state (nonisolated access guarded by isolation below)

    private let peerID = MCPeerID(displayName: ProcessInfo.processInfo.hostName)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Called when a template is received from a peer.
    public var onTemplateReceived: (@Sendable ([String: Any]) -> Void)?

    /// Called when a live-timer tick is received.
    public var onTimerTickReceived: (@Sendable (Int) -> Void)?

    /// Called when a peer connects or disconnects.
    public var onPeerStateChanged: (@Sendable (MCPeerID, MCSessionState) -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Start / stop

    /// Starts advertising and browsing for nearby HabitKit peers.
    public func start() {
        let mcSession = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        mcSession.delegate = self
        self.session = mcSession

        let adv = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: Self.serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        self.advertiser = adv

        let brw = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: Self.serviceType
        )
        brw.delegate = self
        brw.startBrowsingForPeers()
        self.browser = brw
    }

    /// Stops all multipeer activity.
    public func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        session = nil
        advertiser = nil
        browser = nil
    }

    // MARK: - Sending

    /// Sends a habit template to all connected peers.
    ///
    /// - Parameter template: A JSON-serialisable dictionary of template data.
    public func sendTemplate(_ template: [String: Any]) {
        guard let session, !session.connectedPeers.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: template) else { return }
        var payload = Data([0x01])  // message type: template
        payload.append(data)
        try? session.send(payload, toPeers: session.connectedPeers, with: .reliable)
    }

    /// Broadcasts a live timer remaining-seconds value to all connected peers.
    ///
    /// - Parameter remainingSeconds: The current timer countdown value.
    public func sendTimerTick(remainingSeconds: Int) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        var payload = Data([0x02])  // message type: timer tick
        withUnsafeBytes(of: Int32(remainingSeconds)) { payload.append(contentsOf: $0) }
        try? session.send(payload, toPeers: session.connectedPeers, with: .unreliable)
    }
}

// MARK: - MCSessionDelegate

extension MultipeerSession: MCSessionDelegate {
    public func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        onPeerStateChanged?(peerID, state)
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard !data.isEmpty else { return }
        let type = data[0]
        let body = data.dropFirst()

        switch type {
        case 0x01:
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return
            }
            onTemplateReceived?(json)

        case 0x02:
            guard body.count >= 4 else { return }
            let seconds = body.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
            onTimerTickReceived?(Int(seconds))

        default:
            break
        }
    }

    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        guard let session else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    public func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {}
}
