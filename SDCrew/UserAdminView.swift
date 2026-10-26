//
//  UserAdminView.swift
//  my Pilot
//
//  Administrator screens: list users by status, add users (with invite codes), approve,
//  deactivate, reactivate, archive and restore, and change roles.
//

import SwiftUI
import UIKit

// MARK: - Model

@MainActor
@Observable
final class UserAdminModel {

    var users: [AppUser] = []
    var isLoading = false
    var errorMessage: String?

    private let service: CloudKitService

    init(service: CloudKitService = .shared) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await service.fetchAllUsers()
        } catch {
            errorMessage = error.friendlyCloudKitMessage
        }
    }

    func user(id: String) -> AppUser? {
        users.first { $0.id == id }
    }

    /// Saves to CloudKit and updates the local list. Returns whether the save succeeded.
    @discardableResult
    func save(_ user: AppUser) async -> Bool {
        do {
            let saved = try await service.save(user)
            if let index = users.firstIndex(where: { $0.id == saved.id }) {
                users[index] = saved
            } else {
                users.append(saved)
            }
            users.sort { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
            return true
        } catch {
            errorMessage = error.friendlyCloudKitMessage
            return false
        }
    }

    /// Adds an active user with a fresh invite code for them to link their device.
    func addUser(firstName: String, lastName: String, email: String, role: UserRole) async -> Bool {
        let user = AppUser(firstName: firstName.trimmingCharacters(in: .whitespaces),
                           lastName: lastName.trimmingCharacters(in: .whitespaces),
                           email: email.trimmingCharacters(in: .whitespaces),
                           role: role,
                           status: .active,
                           inviteCode: AppUser.makeInviteCode())
        return await save(user)
    }

    func setStatus(_ status: UserStatus, for user: AppUser) async -> Bool {
        var updated = user
        updated.status = status
        updated.statusChangedAt = Date()
        return await save(updated)
    }

    func regenerateInviteCode(for user: AppUser) async -> Bool {
        var updated = user
        updated.inviteCode = AppUser.makeInviteCode()
        return await save(updated)
    }
}

// MARK: - List

struct UserAdminView: View {

    let store: SessionStore

    @State private var model = UserAdminModel()
    @State private var filter: UserStatus = .active
    @State private var isAddingUser = false
    @Environment(\.dismiss) private var dismiss

    private var filteredUsers: [AppUser] {
        model.users.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredUsers) { user in
                    NavigationLink(value: user.id) {
                        UserRowView(user: user, isCurrentUser: isCurrentUser(user))
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Status", selection: $filter) {
                    ForEach(UserStatus.allCases) { status in
                        Text(status.shortName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .overlay {
                if filteredUsers.isEmpty {
                    if model.isLoading {
                        ProgressView()
                    } else {
                        ContentUnavailableView("No \(filter.shortName.lowercased()) users",
                                               systemImage: "person.2.slash",
                                               description: Text(emptyDescription))
                    }
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { userID in
                UserDetailView(userID: userID, model: model, store: store)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingUser = true
                    } label: {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
            .refreshable { await model.load() }
            .task { await model.load() }
            .sheet(isPresented: $isAddingUser) {
                AddUserSheet(model: model)
            }
            .alert("Something went wrong", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private func isCurrentUser(_ user: AppUser) -> Bool {
        user.iCloudUserRecordName != nil && user.iCloudUserRecordName == store.iCloudUserRecordName
    }

    private var emptyDescription: String {
        switch filter {
        case .pending: return "Pilots who request access from the welcome screen appear here."
        case .active: return "Tap + to add a user."
        case .deactivated: return "Deactivated users can be reactivated from their details."
        case .archived: return "Archived users are kept for history and can be restored."
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }
}

private struct UserRowView: View {
    let user: AppUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.fullName.isEmpty ? "Unnamed user" : user.fullName)
                        .font(.headline)
                    if isCurrentUser {
                        Text("You")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }
                }
                Text(user.email.isEmpty ? "No email" : user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !user.isLinked, let code = user.inviteCode {
                    Text("Invite code \(code) not used yet")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(user.role.displayName)
                .font(.caption)
                .foregroundStyle(user.role == .admin ? Color.accentColor : Color.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add

private struct AddUserSheet: View {

    let model: UserAdminModel

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var role: UserRole = .pilot
    @State private var isSaving = false

    private var hasValidName: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Text("An invite code is generated for the new user. Share it with them so they can link their device from the my Pilot welcome screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        isSaving = true
                        Task {
                            if await model.addUser(firstName: firstName, lastName: lastName, email: email, role: role) {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(!hasValidName || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - Detail

private struct UserDetailView: View {

    let userID: String
    let model: UserAdminModel
    let store: SessionStore

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var role: UserRole = .pilot
    @State private var isSaving = false
    @State private var isConfirmingArchive = false

    private var user: AppUser? { model.user(id: userID) }

    /// Administrators may not change their own role or status, which prevents lock-out.
    private var isCurrentUser: Bool {
        guard let linked = user?.iCloudUserRecordName else { return false }
        return linked == store.iCloudUserRecordName
    }

    private var hasEdits: Bool {
        guard let user else { return false }
        return firstName != user.firstName
            || lastName != user.lastName
            || email != user.email
            || role != user.role
    }

    var body: some View {
        if let user {
            Form {
                Section("Details") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .disabled(isCurrentUser)
                }

                Section("Status") {
                    LabeledContent("Status", value: user.status.displayName)
                    if let changed = user.statusChangedAt {
                        LabeledContent("Changed", value: changed.formatted(date: .abbreviated, time: .shortened))
                    }
                    LabeledContent("Device", value: user.isLinked ? "Linked" : "Not linked yet")
                    statusActions(for: user)
                }

                if !user.isLinked {
                    Section {
                        HStack {
                            Text(user.inviteCode ?? "—")
                                .font(.title2.monospaced())
                            Spacer()
                            if let code = user.inviteCode {
                                Button {
                                    UIPasteboard.general.string = code
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        Button("Generate new code") {
                            perform { await model.regenerateInviteCode(for: user) }
                        }
                    } header: {
                        Text("Invite code")
                    } footer: {
                        Text("The user enters this code on the welcome screen to link their iCloud account. Generating a new code invalidates the old one.")
                    }
                }

                if isCurrentUser {
                    Section {
                        Text("You cannot change your own role or status. Ask another administrator to do it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(user.fullName.isEmpty ? "User" : user.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdits(to: user) }
                        .disabled(!hasEdits || isSaving)
                }
            }
            .disabled(isSaving)
            .onAppear { load(from: user) }
            .confirmationDialog("Archive \(user.fullName)?", isPresented: $isConfirmingArchive, titleVisibility: .visible) {
                Button("Archive", role: .destructive) {
                    perform { await model.setStatus(.archived, for: user) }
                }
            } message: {
                Text("Archived users cannot sign in and are hidden from the Active list. Their flight history is kept.")
            }
        } else {
            ContentUnavailableView("User not found", systemImage: "person.slash")
        }
    }

    @ViewBuilder
    private func statusActions(for user: AppUser) -> some View {
        if !isCurrentUser {
            switch user.status {
            case .pending:
                Button("Approve") { perform { await model.setStatus(.active, for: user) } }
                Button("Archive", role: .destructive) { isConfirmingArchive = true }
            case .active:
                Button("Deactivate", role: .destructive) { perform { await model.setStatus(.deactivated, for: user) } }
                Button("Archive", role: .destructive) { isConfirmingArchive = true }
            case .deactivated:
                Button("Reactivate") { perform { await model.setStatus(.active, for: user) } }
                Button("Archive", role: .destructive) { isConfirmingArchive = true }
            case .archived:
                Button("Restore as deactivated") { perform { await model.setStatus(.deactivated, for: user) } }
            }
        }
    }

    private func load(from user: AppUser) {
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        role = user.role
    }

    private func saveEdits(to user: AppUser) {
        var updated = user
        updated.firstName = firstName.trimmingCharacters(in: .whitespaces)
        updated.lastName = lastName.trimmingCharacters(in: .whitespaces)
        updated.email = email.trimmingCharacters(in: .whitespaces)
        updated.role = role
        perform { await model.save(updated) }
    }

    private func perform(_ work: @escaping () async -> Bool) {
        isSaving = true
        Task {
            _ = await work()
            isSaving = false
        }
    }
}
