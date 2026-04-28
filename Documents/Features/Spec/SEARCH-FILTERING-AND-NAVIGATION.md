# Search, Filtering, and Navigation

SimControl provides fast navigation for users with many simulator devices, runtimes, installed apps, and development utilities. Search and filtering are available in the main window, while the menu bar favors pinned and recent targets.

## Global Search

Global search finds devices, runtimes, device types, installed apps, bundle identifiers, UDIDs, and known paths. Results update as the user types.

Searching a bundle identifier should lead to the installed app and its simulator. Searching a UDID should lead to the matching simulator device.

## Device Filters

Devices can be filtered by:

- Platform
- Runtime
- State
- Availability
- Whether installed apps are present
- Pinned status

Active filters are visible and can be removed without losing the current search query.

## App Filters

Installed apps can be filtered by:

- App name
- Bundle identifier
- System app status
- App Group presence
- Detected database files

App filters apply within the selected device or app list without changing the device selection.

## Sorting

Devices can be sorted by name, state, runtime, platform, last booted date, and data size. Apps can be sorted by name, bundle identifier, version, and calculated data size.

The user's preferred sort order is saved and restored when the app opens again.

## Pinned Devices and Apps

Users can pin frequently used devices and apps. Pinned items appear in a dedicated area of the main window and near the top of the menu bar.

Pinned records persist across app restarts. If a pinned target no longer exists, SimControl shows it as missing or removes it after user confirmation.

## Recent Targets

SimControl tracks useful recent targets such as devices, apps, URLs, push payloads, locations, and output folders. Recent data can be cleared from Settings.

Sensitive recent data is stored only when appropriate for the feature and the user's settings.

## Command Palette

The command palette provides keyboard-driven access to common actions, including refresh, boot, shutdown, app launch, folder open, device creation, Settings, and diagnostics.

Commands respect the current selection and disabled states. Disabled commands explain why they cannot run.

## Selection Persistence

SimControl preserves the last selected device and app when possible. Refresh does not reset selection if the selected target still exists.

If a selected target disappears, the app clears selection or moves to a nearby valid item without leaving stale inspector content.

## Menu Bar Navigation

The menu bar remains usable even with large simulator inventories. It groups items by pinned devices, recent devices, platform, and runtime. Settings control how many devices or apps are shown directly.

Complex browsing can continue in the main window through an `Open in Main Window` action.

## Keyboard Shortcuts

Keyboard shortcuts are available for refresh, search, command palette, Settings, and common selected-device actions. Shortcuts follow macOS conventions and are discoverable in menus or tooltips.
