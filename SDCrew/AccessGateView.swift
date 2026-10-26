//
//  AccessGateView.swift
//  my Pilot
//
//  Welcome screen shown until the device's iCloud account maps to an active AppUser.
//  Handles: iCloud unavailable, first administrator setup, invite code / access request,
//  pending, deactivated and archived accounts.
//

import SwiftUI

struct AccessGateView: View {

    let store: SessionStore
    /// Called once the session becomes authorized so the host can swap in the main UI.
    let onAuthorized: @MainActor () -> Void

    @Environment(\.openURL) private var openURL

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var inviteCode = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("my Pilot")
                .navigationBarTitleDisplayMode(.large)
        }
        .task {
            switch store.state {
            case .idle: await store.refresh()
            case .authorized: onAuthorized()
            default: break
            }
        }
        .onChange(of: store.state) { _, newState in
            if case .authorized = newState { onAuthorized() }
        }
        .alert("Something went wrong", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Content per state

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .checking, .authorized:
            statusView(systemImage: "icloud", title: "Checking iCloud access…", message: nil, showsProgress: true) {
                EmptyView()
            }

        case .signedOut:
            statusView(systemImage: "person.crop.circle.badge.checkmark",
                       title: "Signed out",
                       message: "my Pilot uses the iCloud account signed in on this device.") {
                Button("Continue with this device's iCloud account") {
                    Task { await store.refresh() }
                }
                .buttonStyle(.borderedProminent)
            }

        case .iCloudUnavailable(let message):
            statusView(systemImage: "icloud.slash", title: "iCloud is not available", message: message) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.borderedProminent)
                retryButton("Try again")
            }

        case .setupRequired:
            setupForm

        case .unlinked:
            unlinkedForm

        case .pending:
            statusView(systemImage: "hourglass",
                       title: "Access requested",
                       message: "An administrator needs to approve your account before you can continue.") {
                retryButton("Check again")
            }

        case .deactivated:
            statusView(systemImage: "person.crop.circle.badge.xmark",
                       title: "Account deactivated",
                       message: "Your account has been deactivated. Contact your administrator to restore access.") {
                retryButton("Check again")
            }

        case .archived:
            statusView(systemImage: "archivebox",
                       title: "Account archived",
                       message: "Your account has been archived. Contact your administrator if you need access again.") {
                retryButton("Check again")
            }

        case .failed(let message):
            statusView(systemImage: "exclamationmark.triangle", title: "Could not reach iCloud", message: message) {
                retryButton("Try again")
            }
        }
    }

    private var setupForm: some View {
        Form {
            Section {
                Text("No users exist yet. Set up this iCloud account as the first administrator. You can add pilots and other administrators afterwards from the Users screen.")
            }
            Section("Your details") {
                nameFields
            }
            Section {
                Button {
                    run { try await store.setUpFirstAdministrator(firstName: firstName, lastName: lastName, email: email) }
                } label: {
                    Label("Set up as administrator", systemImage: "person.badge.key")
                }
                .disabled(!hasValidName || isWorking)
            }
        }
        .overlay { if isWorking { ProgressView() } }
    }

    private var unlinkedForm: some View {
        Form {
            Section {
                TextField("Invite code", text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.body.monospaced())
                Button("Link this device") {
                    run { try await store.claimInvite(code: inviteCode) }
                }
                .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 || isWorking)
            } header: {
                Text("Have an invite code?")
            } footer: {
                Text("Your administrator can give you a code from the Users screen.")
            }

            Section {
                nameFields
                Button("Request access") {
                    run { try await store.requestAccess(firstName: firstName, lastName: lastName, email: email) }
                }
                .disabled(!hasValidName || isWorking)
            } header: {
                Text("No code? Request access")
            } footer: {
                Text("An administrator will need to approve your request before you can use the app.")
            }
        }
        .overlay { if isWorking { ProgressView() } }
    }

    private var nameFields: some View {
        Group {
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
    }

    // MARK: - Pieces

    private func statusView<Actions: View>(systemImage: String,
                                           title: String,
                                           message: String?,
                                           showsProgress: Bool = false,
                                           @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 16) {
            Spacer()
            if showsProgress {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            if let message, !message.isEmpty {
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            actions()
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func retryButton(_ title: String) -> some View {
        Button(title) {
            Task { await store.refresh() }
        }
        .buttonStyle(.bordered)
    }

    private var hasValidName: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    /// Runs a store action, showing progress and surfacing any error in an alert.
    private func run(_ work: @escaping () async throws -> Void) {
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await work()
            } catch {
                errorMessage = error.friendlyCloudKitMessage
            }
        }
    }
}
