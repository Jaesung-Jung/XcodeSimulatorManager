# Settings, Data, Errors, and Safety

SimControl stores user preferences, records command results, presents recoverable errors clearly, and protects destructive actions with explicit confirmation.

## General Settings

General settings include:

- Launch at login
- Auto refresh
- Refresh debounce interval
- Open Simulator.app after boot
- Boot before app launch
- Boot before installing to another simulator
- Show system apps
- Default output folder for screenshots, recordings, and diagnostics

Settings persist across app restarts. Invalid values are rejected or reset to defaults.

## Xcode Settings

The Xcode settings view shows the active developer path, detected Xcode version, and `simctl` availability. It also includes an environment refresh action and guidance for changing command line tools.

Environment problems appear here with enough context for users to understand what needs to be fixed.

## Menu Bar Settings

Menu bar settings control:

- Pinned devices first
- Maximum devices shown directly
- Maximum apps shown directly per device
- Empty device visibility
- App action visibility
- Dock icon visibility

Changing these settings updates menu bar rendering without changing simulator state.

## Link Folder Settings

Link folder settings include:

- Enable link folder
- Root folder path
- Rebuild links
- Clean stale links
- Open link folder

Link folder actions remain disabled until a root folder is selected. Cleanup requires confirmation.

## Safety Settings

Safety settings control confirmation and command timeout behavior for operations such as app uninstall, device erase, device delete, sandbox reset, and stale link cleanup.

Destructive confirmations are enabled by default. SimControl does not run destructive actions silently.

## About and Attribution

The About view shows the app version, build number, license information, and attribution for the open-source iSimulator project used as a reference during product design.

## Stored Data

SimControl stores:

- User settings
- Pinned devices and apps
- Recent targets
- Link folder root
- Last selected device and app
- Recent command results
- Saved tool presets

Simulator snapshots are rebuilt from `simctl` and file-system state rather than treated as permanent truth. SimControl does not store app data contents.

## Action Log

The action log records simulator command execution results. Entries include the command, arguments, stdout summary, stderr, exit code, duration, start time, and related target.

Recent failures remain inspectable even after a transient alert or status message is dismissed.

## Error Handling

Errors are grouped into user-actionable categories:

- Xcode not selected
- `simctl` command failed
- JSON decode failed
- CoreSimulator path unavailable
- Permission denied
- App container not found
- File operation failed
- Destructive action cancelled

Refresh failure does not replace the last successful snapshot with an empty state. The stale snapshot remains visible with error context.

## Permissions

SimControl distinguishes permission problems from empty simulator state. Read failures for CoreSimulator folders and write failures for link folders or output folders are shown with recovery instructions.

If sandboxed distribution is supported later, user-selected folders and security-scoped bookmarks are used for protected paths.

## Destructive Action Confirmation

Destructive actions require confirmation before execution. The confirmation view includes the target name, identifier, and affected path where applicable.

This applies to:

- App uninstall
- Device erase
- Device delete
- Sandbox reset
- Stale link cleanup

The default button arrangement should not make accidental destructive work easy.

## Command Preconditions

SimControl validates state before commands run. Impossible actions are disabled and explain why they cannot run.

Examples:

- Terminate requires a booted device.
- Screenshot requires a booted device.
- Delete requires a valid device identifier.
- Open container requires a known path or a successful container lookup.

## Diagnostics Export

Diagnostics export collects app version, Xcode path, `simctl` availability, recent command results, selected snapshot metadata, and relevant settings.

Sensitive fields are redacted by default. Users can review the exported file before sharing it.
