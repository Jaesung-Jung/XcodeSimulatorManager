# Installed App Management

SimControl shows the apps installed on each simulator and provides common development actions for launching, stopping, removing, resetting, and copying those apps.

## App Discovery

Installed apps are discovered per simulator device. When possible, SimControl supports discovery even if the simulator is shut down by reading CoreSimulator container folders.

The app scanner matches bundle containers and data containers by bundle identifier. It tolerates partial installs, removed apps, missing metadata, and folders that appear during an install or uninstall operation.

Apple and system apps are hidden by default. A setting can show them when a user needs to inspect the complete simulator environment.

## Metadata and Icons

SimControl reads app metadata from the installed `.app/Info.plist`. App names use `CFBundleDisplayName`, then `CFBundleName`, then the bundle identifier as fallback.

Icon paths are resolved from bundle icon metadata such as `CFBundleIconFile`, `CFBundleIconFiles`, `CFBundleIcons`, and `CFBundleIcons~ipad`. If those entries do not resolve to a usable PNG, SimControl falls back to AppIcon-named PNG files in the app bundle.

App details include:

- Icon
- Display name
- Bundle identifier
- Short version
- Build version
- Bundle container
- Data container
- App Groups

If the app icon cannot be resolved or loaded as a valid image, SimControl displays a default app icon. Icon loading happens in the row view and does not block inventory refresh.

## Launch

An installed app can be launched from the main window or the menu bar. If the target simulator is shut down, SimControl follows the user's boot-before-launch setting.

Launch actions record the command result and refresh relevant state after completion.

## Terminate

Apps can be terminated on booted simulators. Terminate is not offered for unavailable or shutdown devices. If the app is not running, SimControl records the command result without treating it as an application crash.

## Uninstall

Uninstall removes an app from a simulator. It requires confirmation that includes the app name, bundle identifier, device name, and device UDID.

SimControl may attempt to terminate the app before uninstalling it. After uninstall completes, the installed app list is refreshed.

## Sandbox Reset

Sandbox reset deletes the contents of an app's data container while leaving the app installed. The confirmation view shows the app identity and target sandbox path before deletion.

Partial file deletion failures are shown in the result so the user can inspect what remains.

## Install and Launch on Another Simulator

An app installed on one simulator can be installed onto another compatible simulator using the source app bundle. Target simulators are filtered by platform compatibility.

If the target simulator is shut down, SimControl follows the boot-before-install setting. The user can choose whether to launch the app after installation.

## App Groups

SimControl shows App Group containers associated with installed apps when they can be detected from entitlement metadata and matched to CoreSimulator App Group containers. Apple and system groups can be hidden with the scanner's system-app filtering mode.

Each App Group entry shows its group identifier and path and can be opened in Finder.

## Database Files

SimControl detects common database files inside an app's data container, including Realm and SQLite files. App rows show a database-count badge when files are present.

When multiple database files are found, the user can choose which file to open. Files are opened with the system default app.

## Size Calculation

Data container size is calculated during app container scanning by walking files under the data container and summing file sizes. The UI shows the calculated value when available and keeps the value absent when the data container cannot be read or is not known.
