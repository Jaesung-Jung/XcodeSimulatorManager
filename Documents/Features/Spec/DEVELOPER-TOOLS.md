# Developer Tools

SimControl includes simulator utilities commonly used during app development and QA. These tools are available from the main window, and compact versions can be exposed from the menu bar when the interaction is simple enough.

## Deep Links and URLs

Users can open a URL or app deep link on a selected simulator. The tool validates non-empty input and requires a recognizable URL scheme.

Recent URLs are stored for reuse. If the selected simulator is shut down, SimControl follows the user's boot-before-action setting.

## Push Notifications

SimControl can send simulated push notifications to an app on a selected simulator. Payloads can be entered directly or loaded from JSON files.

The tool validates JSON before running the command and lets the user select or infer the target bundle identifier. Recent payloads or file references are stored only according to privacy settings.

## Privacy Permissions

Privacy permissions can be granted, revoked, or reset for an app on a simulator. Supported services depend on the installed `simctl` version and may include camera, photos, microphone, contacts, calendars, location, notifications, and Bluetooth.

Unsupported services are hidden or disabled with an explanation.

## Location Presets

Users can set simulator location with latitude and longitude values. Named presets and recent locations make repeated testing easier.

Invalid coordinates are rejected before command execution. Where supported, simulated location can also be cleared or stopped.

## Status Bar Overrides

The status bar editor applies Simulator status bar overrides such as time, battery, cellular, Wi-Fi, and appearance values. Reusable override presets can be saved.

Overrides can be cleared from the same tool. Known invalid combinations are prevented before execution.

## Screenshots

A selected booted simulator can produce a screenshot saved to a user-visible output folder. After capture, SimControl can reveal the output file in Finder.

Screenshot actions are disabled for shutdown or unavailable devices.

## Video Recording

Video recording can be started and stopped for a selected booted simulator. The UI shows active recording state and prevents duplicate recordings for the same device unless the platform supports it.

Recordings are saved to a user-visible output folder.

## Device Logs

SimControl can open or stream logs for a selected simulator. Filtering by process, subsystem, or text can be provided when feasible.

The log tool also provides a direct action to reveal the simulator log folder in Finder.

## Data Size Analysis

The storage analyzer measures simulator data by device, app, bundle container, data container, and App Group. Size calculations run off the main thread.

Large data consumers are highlighted. Cleanup suggestions are shown separately and never delete data without explicit confirmation.

## Runtime Compatibility Warnings

Before running actions that depend on platform or runtime compatibility, SimControl warns when the selected target is likely incompatible. Structured `simctl` fields are used where available.

Known-invalid actions are blocked. Uncertain cases are presented as warnings rather than hard failures.

## Diagnostics Export

Diagnostics export collects useful troubleshooting information such as app version, Xcode path, `simctl` availability, recent command results, selected snapshot metadata, and relevant settings.

Sensitive app data contents are excluded by default, and users can review the exported file before sharing it.
