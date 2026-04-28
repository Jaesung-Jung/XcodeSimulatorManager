# App Lifecycle and UI Surfaces

SimControl has two primary surfaces: a full app window and a menu bar controller. The app window is used for browsing and detailed management. The menu bar is used for quick actions and remains available after the main window is closed.

## App Lifecycle

Closing the main window does not quit SimControl. The process remains running until the user explicitly selects `Quit SimControl` from the app menu or the menu bar. While the process is running, the menu bar item remains available and can continue to refresh state, boot devices, launch apps, open folders, and reopen the main window.

If the SimControl process is actually terminated, menu bar functionality stops as well. The app does not attempt to provide simulator controls after process termination.

## Menu Bar Interface

The menu bar item appears as soon as SimControl launches. It presents the current simulator state from the app's stored snapshot and does not run expensive `simctl` commands or file scans while the menu is opening.

The menu bar includes:

- Current status and refresh state
- Refresh
- Open SimControl
- Open Simulator.app
- Pinned devices
- All devices grouped by platform or runtime
- Device actions
- Installed app actions
- Settings
- Quit SimControl

Actions started from the menu bar use the same action layer as the main window. Long-running work is shown with disabled or running states so the user does not accidentally start the same command repeatedly.

## Main Window

The main window is the primary place for browsing and detailed work. It opens to the simulator management interface rather than a landing page.

The window contains:

- A toolbar for refresh, Simulator.app, creation tools, search, and settings
- A sidebar for platforms, runtimes, state filters, and pinned items
- A device list or table
- A device inspector
- Installed app details
- Recent command results

Selecting a device updates the inspector and installed app area. If the window is closed, `Open SimControl` from the menu bar restores it. If an existing window is hidden behind other apps, the same action activates SimControl and focuses the window.

## Shared Behavior

The main window and menu bar are different views of the same app state. They do not maintain separate simulator logic.

The same boot, shutdown, app launch, folder open, delete, erase, and refresh actions produce the same command result format regardless of where they are started. Failures expose the same stderr, exit code, and target context in both surfaces.

## Dock and Activation

SimControl starts as a regular macOS app with Dock and Cmd-Tab presence. A setting may allow the Dock icon to be hidden later, but hiding the Dock icon must not remove access to `Open SimControl`, Settings, or Quit from the menu bar.

## Responsiveness

The UI remains responsive during refresh, command execution, app scanning, size calculation, and link-folder maintenance. Menus render from cached state. Work that touches `simctl` or the file system runs asynchronously and updates the shared app state when complete.
