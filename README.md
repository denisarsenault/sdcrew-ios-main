# my Pilot (SDCrew)

iOS app for flight crews to view their flight legs. Access is controlled through CloudKit:
a person's identity is the iCloud account signed in on their device, and what they may do is
decided by an `AppUser` record that an administrator manages from inside the app.

Bundle identifier: `com.hawknestsoftware.mypilot`
CloudKit container: `iCloud.com.hawknestsoftware.mypilot` (public database)

## How access works

1. On launch the app checks that an iCloud account is signed in on the device.
2. It looks for an `AppUser` record linked to that account.
   - **No records at all**: the welcome screen offers to set this account up as the first administrator.
   - **Records exist but none match**: the person can enter an invite code from an administrator, or request access (creating a `pending` record).
   - **Matching record**: the status decides what happens.

| Status | Effect |
|---|---|
| `active` | Full access to the flight leg list. |
| `pending` | Waiting for an administrator to approve. |
| `deactivated` | Blocked, but still listed so an administrator can reactivate. |
| `archived` | Blocked and hidden from the default lists. Never deleted, so history stays intact. |

Roles are `admin` and `pilot`. Administrators get a **Manage Users** entry in the account
sheet (tap the account button on the flight leg list) where they can add users with invite
codes, approve, deactivate, reactivate, archive, restore and change roles.

Each time the app returns to the foreground it re-reads the signed-in user's record, so a
deactivation or archive by an administrator takes effect without a restart.

## Project layout

| Path | Purpose |
|---|---|
| `SDCrew/CloudKit/AppUser.swift` | The `AppUser` model, field names and record mapping. |
| `SDCrew/CloudKit/CloudKitService.swift` | Async wrapper over the public database: fetch, query and save users. |
| `SDCrew/CloudKit/SessionStore.swift` | Observable session state: iCloud check, lookup, first-admin setup, invite claim, access request. |
| `SDCrew/CloudKit/AppUser.ckdb` | CloudKit schema for the `AppUser` record type. Import this into a new container. |
| `SDCrew/AccessGateView.swift` | SwiftUI welcome screen shown until the account is authorized. |
| `SDCrew/UserAdminView.swift` | SwiftUI user administration screens for administrators. |
| `SDCrew/LoginSwitcher.swift` | Swaps the window's root between the access gate and the flight leg list. |
| `SDCrew/SDCrew.entitlements` | iCloud and CloudKit entitlements. |

## CloudKit setup

The container must have the `AppUser` record type before the app can query it. The schema
lives in `SDCrew/CloudKit/AppUser.ckdb` and should be imported into the **Development**
environment first, then deployed to **Production** before a TestFlight or App Store build.

### Option A: CloudKit Console

1. Open the [CloudKit Console](https://icloud.developer.apple.com/) and select the container `iCloud.com.hawknestsoftware.mypilot`.
2. Choose the Development environment, then **Schema**, then **Import Schema**.
3. Pick `SDCrew/CloudKit/AppUser.ckdb` and confirm.

### Option B: `cktool`

Generate a management token in the console under Account Settings, then Tokens, then
Management Tokens, and run:

```sh
xcrun cktool save-token
xcrun cktool import-schema \
    --team-id B8P24AZNQT \
    --container-id iCloud.com.hawknestsoftware.mypilot \
    --environment development \
    --file SDCrew/CloudKit/AppUser.ckdb
```

### What the schema defines

Record type `AppUser` with these fields:

| Field | Type | Index |
|---|---|---|
| `firstName` | String | |
| `lastName` | String | |
| `email` | String | |
| `role` | String | |
| `status` | String | QUERYABLE |
| `iCloudUserRecordName` | String | QUERYABLE |
| `inviteCode` | String | QUERYABLE |
| `statusChangedAt` | Date/Time | |

Security role `_icloud` (any signed-in iCloud user) is granted Read, Create and Write.
Write is needed because administrators modify records they did not create, and pilots
write their iCloud identity onto records an administrator created for them.

If you change `AppUser.Field` in `AppUser.swift`, update `AppUser.ckdb` to match and
re-import.

### Deploying to Production

In the console, choose **Deploy Schema Changes** on the Development environment. Records
are not copied; Production starts empty and the first person to launch a production build
becomes the first administrator.

## Running and testing

- **Simulator**: CloudKit needs an iCloud account. Sign in under Settings in the simulator, or the app stops at the "iCloud is not available" screen.
- **Device**: run on a signed-in iPhone. The first launch against an empty container shows the first-administrator setup form.
- **Logs**: session state changes are logged under subsystem `com.hawknestsoftware.mypilot`, category `Session`. A `failed(...)` state carries the CloudKit error text.

Common CloudKit errors:

| Message | Fix |
|---|---|
| Field is not marked queryable | Add a QUERYABLE index for that field in the console. |
| Permission failure on save | Give `_icloud` Create and Write on `AppUser` under Security Roles. |
| Did not find record type | The schema has not been imported into this environment. |

## Flight data

Flight legs, pilots, fuel and notes still come from the existing session API and are cached
in Core Data. Demo mode seeds this data locally. Moving flight data to CloudKit is planned
as a later phase.
