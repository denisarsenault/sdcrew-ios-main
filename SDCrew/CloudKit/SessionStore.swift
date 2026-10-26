//
//  SessionStore.swift
//  my Pilot
//
//  Decides whether the person holding the device may use the app. Identity comes from
//  the device's iCloud account; permission comes from the matching AppUser record.
//

import CloudKit
import Observation
import os

private let logger = Logger(subsystem: "com.hawknestsoftware.mypilot", category: "Session")

@MainActor
@Observable
final class SessionStore {

    enum State: Equatable {
        /// Nothing checked yet.
        case idle
        case checking
        /// The person chose Sign Out; a tap is required before re-checking.
        case signedOut
        case iCloudUnavailable(String)
        /// No AppUser exists at all: offer to set this account up as the first administrator.
        case setupRequired
        /// Users exist but none is linked to this iCloud account: claim an invite or request access.
        case unlinked
        case pending(AppUser)
        case deactivated(AppUser)
        case archived(AppUser)
        case authorized(AppUser)
        case failed(String)
    }

    static let shared = SessionStore()

    private(set) var state: State = .idle {
        didSet { logger.info("Session state: \(String(describing: self.state), privacy: .public)") }
    }
    /// Record name of the iCloud account on this device, once known.
    private(set) var iCloudUserRecordName: String?

    private let service: CloudKitService

    init(service: CloudKitService = .shared) {
        self.service = service
    }

    var currentUser: AppUser? {
        if case .authorized(let user) = state { return user }
        return nil
    }

    var isAuthorized: Bool { currentUser != nil }

    var isAdmin: Bool { currentUser?.role == .admin }

    // MARK: - Checking access

    func refresh() async {
        state = .checking
        do {
            let accountStatus = try await service.accountStatus()
            guard accountStatus == .available else {
                state = .iCloudUnavailable(Self.message(for: accountStatus))
                return
            }

            let me = try await service.currentUserRecordName()
            iCloudUserRecordName = me

            if let user = try await service.fetchUser(linkedTo: me) {
                state = Self.state(for: user)
            } else if try await service.hasAnyUsers() {
                state = .unlinked
            } else {
                state = .setupRequired
            }
        } catch {
            state = .failed(error.friendlyCloudKitMessage)
        }
    }

    /// Re-reads an authorized user's record so an administrator's deactivation or archiving
    /// takes effect the next time the app comes to the foreground. Returns whether the
    /// person is still authorized. Transient errors leave the current state untouched.
    func revalidate() async -> Bool {
        guard let user = currentUser else { return isAuthorized }
        if let fresh = try? await service.fetchUser(id: user.id) {
            state = Self.state(for: fresh)
        }
        return isAuthorized
    }

    func signOut() {
        state = .signedOut
    }

    // MARK: - Joining

    func setUpFirstAdministrator(firstName: String, lastName: String, email: String) async throws {
        let me = try await requireICloudUser()
        guard try await service.hasAnyUsers() == false else { throw CloudKitServiceError.alreadySetUp }

        let admin = AppUser(firstName: firstName.trimmed,
                            lastName: lastName.trimmed,
                            email: email.trimmed,
                            role: .admin,
                            status: .active,
                            iCloudUserRecordName: me)
        state = Self.state(for: try await service.save(admin))
    }

    func claimInvite(code: String) async throws {
        let me = try await requireICloudUser()
        let normalizedCode = code.trimmed.uppercased()

        guard var user = try await service.fetchUser(inviteCode: normalizedCode) else {
            throw CloudKitServiceError.inviteCodeNotFound
        }
        if let linked = user.iCloudUserRecordName, linked != me {
            throw CloudKitServiceError.inviteCodeAlreadyUsed
        }

        user.iCloudUserRecordName = me
        user.inviteCode = nil
        if user.status == .pending {
            user.status = .active
            user.statusChangedAt = Date()
        }
        state = Self.state(for: try await service.save(user))
    }

    func requestAccess(firstName: String, lastName: String, email: String) async throws {
        let me = try await requireICloudUser()
        if let existing = try await service.fetchUser(linkedTo: me) {
            state = Self.state(for: existing)
            return
        }

        let request = AppUser(firstName: firstName.trimmed,
                              lastName: lastName.trimmed,
                              email: email.trimmed,
                              role: .pilot,
                              status: .pending,
                              iCloudUserRecordName: me)
        state = Self.state(for: try await service.save(request))
    }

    // MARK: - Helpers

    private func requireICloudUser() async throws -> String {
        if let me = iCloudUserRecordName { return me }
        let me = try await service.currentUserRecordName()
        iCloudUserRecordName = me
        return me
    }

    private static func state(for user: AppUser) -> State {
        switch user.status {
        case .active: return .authorized(user)
        case .pending: return .pending(user)
        case .deactivated: return .deactivated(user)
        case .archived: return .archived(user)
        }
    }

    private static func message(for status: CKAccountStatus) -> String {
        switch status {
        case .noAccount:
            return "No iCloud account is signed in on this device. Sign in under Settings and try again."
        case .restricted:
            return "iCloud access is restricted on this device (for example by Screen Time or a device profile)."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Try again in a moment."
        case .couldNotDetermine:
            return "Could not determine the iCloud account status."
        case .available:
            return ""
        @unknown default:
            return "iCloud is not available."
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
