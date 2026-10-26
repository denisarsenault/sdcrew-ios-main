//
//  CloudKitService.swift
//  my Pilot
//
//  Thin async wrapper over the app's CloudKit container. All shared data lives in the
//  public database of the team-owned container, so every device sees the same records.
//
//  CloudKit Console setup required (Development environment, then deploy to Production):
//    * Record type "AppUser" is created on first save (just-in-time schema).
//    * Security roles for AppUser: give `_icloud` (authenticated users) Create, Read and
//      Write. Administrators modify records they did not create, and pilots write their
//      iCloud identity onto records an administrator created.
//    * Indexes: QUERYABLE on iCloudUserRecordName, inviteCode and status.
//

import CloudKit

enum CloudKitServiceError: LocalizedError {
    case inviteCodeNotFound
    case inviteCodeAlreadyUsed
    case alreadySetUp

    var errorDescription: String? {
        switch self {
        case .inviteCodeNotFound:
            return "That invite code was not recognised. Check it with your administrator."
        case .inviteCodeAlreadyUsed:
            return "That invite code has already been used on another device."
        case .alreadySetUp:
            return "An administrator has already been set up. Ask them for an invite code."
        }
    }
}

final class CloudKitService: Sendable {

    /// Matches the container in the app's entitlements.
    static let containerIdentifier = "iCloud.com.hawknestsoftware.mypilot"

    static let shared = CloudKitService()

    let container: CKContainer
    let publicDatabase: CKDatabase

    init(containerIdentifier: String = CloudKitService.containerIdentifier) {
        container = CKContainer(identifier: containerIdentifier)
        publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Identity

    func accountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    /// Stable identifier for the iCloud account signed in on this device.
    func currentUserRecordName() async throws -> String {
        try await container.userRecordID().recordName
    }

    // MARK: - Users

    func fetchUser(linkedTo iCloudUserRecordName: String) async throws -> AppUser? {
        let predicate = NSPredicate(format: "%K == %@", AppUser.Field.iCloudUserRecordName, iCloudUserRecordName)
        return try await queryUsers(predicate, limit: 1).first
    }

    func fetchUser(inviteCode: String) async throws -> AppUser? {
        let predicate = NSPredicate(format: "%K == %@", AppUser.Field.inviteCode, inviteCode)
        return try await queryUsers(predicate, limit: 1).first
    }

    func fetchUser(id: String) async throws -> AppUser {
        let record = try await publicDatabase.record(for: CKRecord.ID(recordName: id))
        return AppUser(record: record)
    }

    /// True when at least one AppUser exists. Used to decide whether to offer first-admin setup.
    func hasAnyUsers() async throws -> Bool {
        try await queryUsers(Self.anyStatusPredicate, limit: 1).isEmpty == false
    }

    func fetchAllUsers() async throws -> [AppUser] {
        let users = try await queryUsers(Self.anyStatusPredicate, limit: CKQueryOperation.maximumResults)
        return users.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    /// Saves every field of the user and returns the server's copy.
    @discardableResult
    func save(_ user: AppUser) async throws -> AppUser {
        let result = try await publicDatabase.modifyRecords(saving: [user.makeRecord()],
                                                            deleting: [],
                                                            savePolicy: .changedKeys,
                                                            atomically: true)
        guard let saveResult = result.saveResults[user.recordID] else { return user }
        return AppUser(record: try saveResult.get())
    }

    // MARK: - Helpers

    /// A predicate on a real field rather than TRUEPREDICATE, which would need the
    /// recordName index that the console does not create automatically.
    private static var anyStatusPredicate: NSPredicate {
        NSPredicate(format: "%K IN %@", AppUser.Field.status, UserStatus.allCases.map(\.rawValue))
    }

    private func queryUsers(_ predicate: NSPredicate, limit: Int) async throws -> [AppUser] {
        let query = CKQuery(recordType: AppUser.recordType, predicate: predicate)
        var users: [AppUser] = []

        do {
            var (matchResults, cursor) = try await publicDatabase.records(matching: query, resultsLimit: limit)
            users.append(contentsOf: Self.users(from: matchResults))

            while let nextCursor = cursor, users.count < limit {
                (matchResults, cursor) = try await publicDatabase.records(continuingMatchFrom: nextCursor,
                                                                          resultsLimit: limit - users.count)
                users.append(contentsOf: Self.users(from: matchResults))
            }
        } catch let error as CKError where Self.isMissingRecordType(error) {
            // A brand-new container has no AppUser type yet; the first save creates it.
            return []
        }
        return users
    }

    /// CloudKit reports a query against a record type that does not exist yet as an error
    /// rather than an empty result.
    private static func isMissingRecordType(_ error: CKError) -> Bool {
        (error.code == .unknownItem || error.code == .invalidArguments)
            && error.localizedDescription.localizedCaseInsensitiveContains("Did not find record type")
    }

    private static func users(from matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)]) -> [AppUser] {
        matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return AppUser(record: record)
        }
    }
}

extension Error {
    /// A message suitable for showing to a pilot, with hints for the common CloudKit failures.
    var friendlyCloudKitMessage: String {
        guard let ckError = self as? CKError else { return localizedDescription }
        switch ckError.code {
        case .notAuthenticated:
            return "Sign in to iCloud in Settings to use my Pilot."
        case .networkUnavailable, .networkFailure:
            return "No network connection. Check Wi-Fi or cellular and try again."
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return "iCloud is busy right now. Please try again in a moment."
        case .permissionFailure:
            return "iCloud refused the change. The AppUser security role needs Write access for signed-in users (CloudKit Console)."
        case .invalidArguments, .unknownItem:
            return "\(ckError.localizedDescription) If this mentions a field not being queryable, add a QUERYABLE index for it in the CloudKit Console."
        default:
            return ckError.localizedDescription
        }
    }
}
