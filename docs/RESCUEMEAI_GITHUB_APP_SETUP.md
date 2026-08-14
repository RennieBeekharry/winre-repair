# RescueMeAI™ Development GitHub App Setup

This document describes the temporary GitHub development backend used for RescueMeAI recovery pairing. The production architecture should eventually use a dedicated RescueMeAI relay or equivalent narrowly scoped provider.

## Security objective

The recovery PC must not receive a classic OAuth `repo` token with account-wide private-repository access.

For development, use a dedicated GitHub App that:

- is owned by the recovery project owner;
- has Device Flow enabled for headless WinRE authorization;
- has only the minimum repository permissions required;
- is installed on **only** the private recovery evidence/control repository;
- issues a user access token through GitHub App device flow;
- is removable/revocable after the recovery session.

## App registration

Create a GitHub App under the account that owns the recovery repositories.

Recommended development values:

- **GitHub App name:** `RescueMeAI-<owner>-Recovery` or another unique RescueMeAI development name.
- **Homepage URL:** the public RescueMeAI source repository URL.
- **Callback URL:** not required for the Device Flow path.
- **Request user authorization during installation:** not required.
- **Enable Device Flow:** YES.
- **Webhooks Active:** NO for the current polling-based development backend.
- **Repository permissions → Contents:** Read & write.
- **All other optional repository/account/organization permissions:** No access unless a later feature has a documented need.
- **Where can this GitHub App be installed?:** Only on this account.

GitHub automatically provides the metadata access required by GitHub Apps.

## Installation

After creating the app:

1. Open the app's **Install App** page.
2. Install it on the recovery repository owner's account.
3. Select **Only select repositories**.
4. Select only `winre-repair-logs` for the current development recovery backend.
5. Review the permissions and install.

Do not select **All repositories**.

## Client ID

On the GitHub App settings page, copy the **Client ID**.

The Client ID is an application identifier, not an authentication secret. Do not copy or share the app private key or client secret for this WinRE device-flow design.

Provide the Client ID to the RescueMeAI project configuration. The recovery PC will receive it through the signed/pinned public runtime configuration rather than requiring the user to type it in WinRE.

## Repository binding

Current private evidence/control repository:

- `RennieBeekharry/winre-repair-logs`
- GitHub repository ID: `1333818657`

The device-token exchange should include this repository ID when supported and the app installation itself must remain restricted to this repository.

## Device pairing

After the GitHub App is configured, RescueMeAI will:

1. establish outbound HTTPS connectivity;
2. request a GitHub App device code using the configured Client ID;
3. display a short one-time code and GitHub verification URL;
4. wait while the user approves the code on a phone;
5. exchange the device code for a GitHub App user access token;
6. test access only against the configured private evidence/control repository;
7. store the resulting recovery credential locally;
8. upload the bootstrap report;
9. proceed to the persistent command-listener validation.

## Revocation

After recovery or whenever the development backend is no longer required, the owner can revoke the GitHub App authorization, suspend/uninstall the app, or remove its repository access.

## Production direction

The GitHub backend is a development transport. Production RescueMeAI should use a purpose-built pairing/relay design that provides short-lived, narrowly scoped session credentials and does not require broad third-party source-control permissions.
