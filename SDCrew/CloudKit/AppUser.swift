//
//  AppUser.swift
//  my Pilot
//
//  App-level user record stored in the CloudKit public database. A person's identity
//  is the iCloud account signed in on their device (CKContainer.userRecordID); what
//  they may do in the app is decided by the role and status on their AppUser record.
//

import CloudKit

enum UserRole: String, CaseIterable, Identifiable, Sendable {
    case admin
    case pilot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .pilot: return "Pilot"
        }
    }
}

enum UserStatus: String, CaseIterable, Identifiable, Sendable {
    /// Self-registered from the welcome screen and waiting for an administrator to approve.
    case pending
    /// Allowed to use the app.
    case active
    /// Blocked from signing in, but still listed so an administrator can reactivate.
    case deactivated
    /// Blocked and hidden from the default lists. Never deleted, so flight history stays intact.
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending approval"
        case .active: return "Active"
        case .deactivated: return "Deactivated"
        case .archived: return "Archived"
        }
    }

    /// Short label for segmented controls.
    var shortName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .deactivated: return "Deactivated"
        case .archived: return "Archived"
        }
    }
}

struct AppUser: Identifiable, Hashable, Sendable {

    static let recordType = "AppUser"

    /// CloudKit field names. Kept in one place so the schema is easy to audit in the console.
    enum Field {
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let email = "email"
        static let role = "role"
        static let status = "status"
        static let iCloudUserRecordName = "iCloudUserRecordName"
        static let inviteCode = "inviteCode"
        static let statusChangedAt = "statusChangedAt"
    }

    /// The CloudKit record name.
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var role: UserRole
    var status: UserStatus
    /// Record name of the iCloud user this app user is linked to, once they have signed in.
    var iCloudUserRecordName: String?
    /// One-time code an administrator gives a pilot so the pilot can link their device.
    var inviteCode: String?
    var statusChangedAt: Date?
    var createdAt: Date?
    var modifiedAt: Date?

    init(id: String = UUID().uuidString,
         firstName: String,
         lastName: String,
         email: String,
         role: UserRole,
         status: UserStatus,
         iCloudUserRecordName: String? = nil,
         inviteCode: String? = nil,
         statusChangedAt: Date? = Date(),
         createdAt: Date? = nil,
         modifiedAt: Date? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.status = status
        self.iCloudUserRecordName = iCloudUserRecordName
        self.inviteCode = inviteCode
        self.statusChangedAt = statusChangedAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Reads a record from CloudKit. Unknown role or status values fall back to the safest
    /// option (pilot / pending) rather than failing.
    init(record: CKRecord) {
        id = record.recordID.recordName
        firstName = record[Field.firstName] as? String ?? ""
        lastName = record[Field.lastName] as? String ?? ""
        email = record[Field.email] as? String ?? ""
        role = UserRole(rawValue: record[Field.role] as? String ?? "") ?? .pilot
        status = UserStatus(rawValue: record[Field.status] as? String ?? "") ?? .pending
        iCloudUserRecordName = record[Field.iCloudUserRecordName] as? String
        inviteCode = record[Field.inviteCode] as? String
        statusChangedAt = record[Field.statusChangedAt] as? Date
        createdAt = record.creationDate
        modifiedAt = record.modificationDate
    }

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    /// Builds a record carrying every field. Saved with the `.changedKeys` policy this
    /// overwrites each field on the server without change-tag conflicts.
    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record[Field.firstName] = firstName
        record[Field.lastName] = lastName
        record[Field.email] = email
        record[Field.role] = role.rawValue
        record[Field.status] = status.rawValue
        record[Field.iCloudUserRecordName] = iCloudUserRecordName
        record[Field.inviteCode] = inviteCode
        record[Field.statusChangedAt] = statusChangedAt
        return record
    }

    var fullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// True once a device's iCloud account has been attached to this user.
    var isLinked: Bool { iCloudUserRecordName != nil }

    var canUseApp: Bool { status == .active }

    /// Six characters from an alphabet without look-alike glyphs (no 0/O, 1/I).
    static func makeInviteCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
