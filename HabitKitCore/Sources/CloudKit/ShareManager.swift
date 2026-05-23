import CloudKit
import Foundation

// MARK: - ShareManager

/// Manages CKShare-based collaborative habit sharing (§8.21).
///
/// A user can share a specific habit with contacts via CloudKit sharing.
/// Shared habits appear in the recipient's HabitKit as a read-only "shared"
/// entry. The owner can revoke access by stopping the share.
public actor ShareManager {

    // MARK: - Shared instance

    public static let shared = ShareManager()

    // MARK: - Private state

    private let container = CKContainer(identifier: "iCloud.com.habitkit.app")
    private var activeShares: [UUID: CKShare] = [:]

    // MARK: - Init

    private init() {}

    // MARK: - Creating shares

    /// Creates a CKShare for the given habit record.
    ///
    /// - Parameters:
    ///   - habitID: The habit to share.
    ///   - habitName: Used as the share's title metadata.
    /// - Returns: The created `CKShare` and its associated `CKRecord`.
    public func createShare(
        for habitID: UUID,
        habitName: String
    ) async throws -> (CKShare, CKRecord) {
        let database = container.privateCloudDatabase

        let recordID = CKRecord.ID(
            recordName: "habit.\(habitID.uuidString)",
            zoneID: CKRecordZone.ID(
                zoneName: "HabitKit",
                ownerName: CKCurrentUserDefaultName
            )
        )
        let record = CKRecord(recordType: "SharedHabit", recordID: recordID)
        record["habitID"] = habitID.uuidString as CKRecordValue
        record["habitName"] = habitName as CKRecordValue
        record["sharedAt"] = Date() as CKRecordValue

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = habitName as CKRecordValue
        share.publicPermission = .none

        let operation = CKModifyRecordsOperation(
            recordsToSave: [record, share],
            recordIDsToDelete: nil
        )
        operation.modifyRecordsResultBlock = { _ in }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }

        activeShares[habitID] = share
        return (share, record)
    }

    /// Stops sharing the habit — all participants lose access.
    ///
    /// - Parameter habitID: The habit whose share should be revoked.
    public func stopSharing(habitID: UUID) async throws {
        guard let share = activeShares[habitID] else { return }
        let database = container.privateCloudDatabase
        try await database.deleteRecord(withID: share.recordID)
        activeShares.removeValue(forKey: habitID)
    }

    // MARK: - Accepting shares

    /// Accepts an incoming CKShare invitation.
    ///
    /// Call from `application(_:userDidAcceptCloudKitShareWith:)`.
    ///
    /// - Parameter metadata: The `CKShare.Metadata` from the system callback.
    public func acceptShare(metadata: CKShare.Metadata) async throws {
        try await container.accept(metadata)
    }

    // MARK: - Querying shared habits

    /// Fetches all habits shared with the current user from the shared database.
    ///
    /// - Returns: Array of `SharedHabitRecord` values.
    public func fetchSharedHabits() async throws -> [SharedHabitRecord] {
        let database = container.sharedCloudDatabase
        let query = CKQuery(
            recordType: "SharedHabit",
            predicate: NSPredicate(value: true)
        )
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { _, result in
            guard let record = try? result.get(),
                  let idString = record["habitID"] as? String,
                  let name = record["habitName"] as? String else { return nil }
            return SharedHabitRecord(
                cloudRecordName: record.recordID.recordName,
                habitID: idString,
                habitName: name
            )
        }
    }
}

// MARK: - SharedHabitRecord

/// Lightweight record describing a habit shared with the current user.
public struct SharedHabitRecord: Sendable {
    public var cloudRecordName: String
    public var habitID: String
    public var habitName: String

    public init(cloudRecordName: String, habitID: String, habitName: String) {
        self.cloudRecordName = cloudRecordName
        self.habitID = habitID
        self.habitName = habitName
    }
}
