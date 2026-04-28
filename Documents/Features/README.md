# SimControl Feature Specification

SimControl is a macOS app for managing Xcode Simulator devices and the apps installed on them. It combines a full SwiftUI management window with a persistent menu bar interface, so common simulator actions remain available even after the main window is closed.

The app is designed for developers who frequently switch devices, inspect app containers, launch test builds, reset simulator state, and run simulator utilities such as deep links, push notifications, location changes, screenshots, and privacy permission changes.

## Feature Documents

- [App Lifecycle and UI Surfaces](Spec/LIFECYCLE-AND-SURFACES.md)
- [Simulator Inventory and Control](Spec/SIMULATOR-INVENTORY-AND-CONTROL.md)
- [Installed App Management](Spec/INSTALLED-APP-MANAGEMENT.md)
- [Containers, Finder, and Link Folders](Spec/CONTAINERS-AND-FILES.md)
- [Developer Tools](Spec/DEVELOPER-TOOLS.md)
- [Search, Filtering, and Navigation](Spec/SEARCH-FILTERING-AND-NAVIGATION.md)
- [Settings, Data, Errors, and Safety](Spec/SETTINGS-DATA-ERRORS-AND-SAFETY.md)

## Feature Summary

- Keep the menu bar controller running until the user explicitly quits SimControl.
- Provide a main management window for browsing devices, runtimes, installed apps, containers, command results, and settings.
- Use the same simulator action system from the main window and the menu bar.
- Detect the active Xcode developer directory and validate `simctl` availability.
- List runtimes, device types, devices, watch/phone pairs, and installed apps.
- Refresh manually and automatically when CoreSimulator files change.
- Boot, shut down, open, create, clone, rename, erase, and delete simulators.
- Pair and unpair compatible watch and phone simulators.
- Launch, terminate, uninstall, reset, and copy installed apps between compatible simulators.
- Open app bundle, sandbox, App Group, device data, and log folders in Finder.
- Optionally create a symbolic-link folder tree for quick access to simulator app data.
- Run developer utilities for URLs, push notifications, privacy permissions, location, status bar overrides, screenshots, video recording, logs, and storage analysis.
- Search, filter, sort, pin, and quickly navigate devices and apps.
- Store user preferences, recent targets, pinned items, action logs, and tool presets.
- Surface command failures with useful stderr, exit code, and recovery context.
- Require clear confirmation before destructive operations.
