# Security Policy: Roblox System & Codebase

This repository contains the source code, tooling, and configurations for our Roblox game system. We take the security of our player data, developer environment, and game assets very seriously.

## Supported Versions

We only provide security updates and patches for the active production version of our Roblox game. 

| Version | Supported          |
| ------- | ------------------ |
| Main    | :x:                |
| Beta    | :white_check_mark: |
| Legacy  | :x:                |

## Reporting a Vulnerability

**Do not open public GitHub issues for security vulnerabilities, exposed tokens, or system exploits.** Publicly disclosing vulnerabilities puts live experiences, player data, and Roblox Group assets at risk.

If you discover a security issue or vulnerability within our codebase, scripts, or runtime environment, please report it privately:

1. **Private Advisory:** Navigate to the "Security" tab of this repository and select "Report a vulnerability" to open a private draft.

Please include a minimal reproduction script, the impacted assets/scripts, and an evaluation of how the exploit could affect the live game or player environment.

## Mandatory Developer Security Rules

All contributors with write access to this repository or editing permissions in our Roblox Group must adhere to the following protocol:

### 1. Hardcoded Secrets & Tokens
* **No Client-Side Secrets:** Never store private API keys, webhooks (e.g., Discord webhooks), or private database credentials inside client-side scripts.
* **Server-Only Isolation:** Sensitive keys must remain strictly in `ServerScriptService` or `ServerStorage`.
* **Git Overrides:** Ensure any local environment variable configs or private `.luau` project profiles are explicitly blocked in the `.gitignore` file.

### 2. Remote Event & Function Validation
* **Zero Client Trust:** Treat all incoming payloads from `RemoteEvents` and `RemoteFunctions` as potentially malicious injections.
* **Server-Side Validation:** The server must rigorously validate all arguments sent by the client (e.g., verifying if a player actually has enough currency before processing a purchase server-side).

### 3. Account and Cookie Integrity
* **Protect `.ROBLOSECURITY`:** Do not commit or share browser cookies, session keys, or `.ROBLOSECURITY` strings. Doing so completely bypasses two-step verification.
* **Enforce Enhanced Protection:** All core repository maintainers must enable "Enhanced Protection" and hardware Passkeys within their Roblox Account settings to mitigate phishing risks.

### 4. Third-Party Plugin & Library Vet
* **Malicious Script Auditing:** Review the source code of any Roblox Studio plugin or external library before importing it into the system environment to prevent backdoor injections.
