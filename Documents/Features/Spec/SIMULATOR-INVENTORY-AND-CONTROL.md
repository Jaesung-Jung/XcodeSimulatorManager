# Simulator Inventory and Control

SimControl uses Xcode command line tools and CoreSimulator data to build a current view of available runtimes, device types, simulator devices, and device pairs. Simulator actions are available from both the main window and the menu bar.

## Xcode and simctl Environment

SimControl detects the active Xcode developer directory with `xcrun xcode-select -p` and shows the result in Settings. It validates that `xcrun simctl` can run before attempting simulator inventory or control actions.

When the active Xcode path changes, SimControl refreshes its simulator snapshot. If Xcode or `simctl` is unavailable, the app shows an environment problem with the command output needed to diagnose it.

## Runtime Inventory

Runtime inventory is based on `simctl list -j`. SimControl uses structured fields such as `platform`, `isAvailable`, `supportedDeviceTypes`, `version`, and `buildversion` where available. It avoids depending on runtime name parsing when structured data exists.

Runtime views show:

- Name
- Platform
- Version
- Build version
- Availability
- Supported device count

Unavailable runtimes remain visible with a warning state instead of disappearing from the app.

## Device Type Inventory

Device types are read from `simctl list -j` and include identifier, name, product family, model identifier, and compatibility information when available.

When creating a simulator, SimControl presents device types compatible with the selected runtime. Unknown product families remain visible and are labeled clearly rather than filtered out silently.

## Device Inventory

Device inventory includes every simulator returned by `simctl list -j`. Devices are grouped by platform and runtime and can be shown in the main list, the inspector, and the menu bar.

Device details include:

- Name
- State
- Runtime
- Platform
- Device type
- UDID
- Availability
- Data path
- Log path
- Last booted date
- Data size when available

Unavailable devices remain visible. Actions that cannot run on those devices are disabled with a clear reason.

## Watch and Phone Pairs

SimControl reads watch/phone pair information from `simctl list -j` and links pair records to known devices. The phone inspector shows paired watches, and watch devices show their paired state when available.

Broken pair records or missing devices are handled as recoverable state rather than inventory failures.

## Refresh

Users can refresh manually from the main window or menu bar. Refresh creates a new simulator snapshot from `simctl` output and relevant CoreSimulator file-system data.

SimControl also watches CoreSimulator folders for changes such as device creation, device deletion, boot or shutdown transitions, and app installation changes. File events are debounced before refresh to avoid repeated work.

If refresh fails, the last successful snapshot remains visible and is marked stale. The failure includes the command, stderr, exit code, and recovery context where available.

## Boot and Shutdown

Shutdown devices can be booted with `simctl boot`. Boot may optionally open Simulator.app afterward, depending on Settings.

Booted devices can be shut down with `simctl shutdown`. Boot and shutdown actions update the shared snapshot after completion and record their command results.

Unavailable devices, already booted devices, and already shutdown devices expose only valid actions.

## Open Simulator.app

Simulator.app can be opened from the toolbar, device inspector, or menu bar. When a selected device is already booted, SimControl should make the opened Simulator.app useful for that context where possible.

## Create, Clone, and Rename

Creating a simulator requires a runtime, device type, and name. If the name is empty, SimControl uses the device type name. After creation, the user can boot the new simulator.

Cloning duplicates an existing simulator under a new name. Renaming changes a simulator's display name and updates list entries, menu items, pinned references, and link-folder naming.

## Erase and Delete

Erase resets a simulator's content and settings. Delete removes the simulator. Both operations are destructive and require confirmation that includes the device name and UDID.

After erase or delete, SimControl refreshes simulator and app state. If the selected simulator disappears, the selection is cleared or moved to a nearby valid device.

## Pair and Unpair

Compatible phone and watch simulators can be paired. Already paired watches are not shown as pair candidates. Existing pairs can be removed with unpair.

Pair and unpair actions refresh pair state after completion and record their command results.
