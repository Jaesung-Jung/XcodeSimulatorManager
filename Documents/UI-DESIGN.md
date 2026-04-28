# SimControl UI Design

SimControl opens directly into a simulator management workspace. The app does not use a landing page. The main window is an operational UI for browsing simulators, inspecting installed apps, opening containers, running simulator tools, and reviewing command results.

This document describes the intended UI structure, layout behavior, interaction model, and implementation boundaries for the main window. It is based on the current prototype direction, but production code should split the layout into focused views rather than keeping the full interface in one file.

## Design Goals

- Give developers a fast overview of simulator inventory as soon as the app opens.
- Keep navigation stable with a persistent sidebar and a main work area.
- Make selected-device context clear at all times.
- Keep frequent actions close to the current selection.
- Show command state and failures without hiding the underlying simulator inventory.
- Use dense, macOS-native controls suitable for repeated developer workflows.
- Avoid marketing-style surfaces, empty hero views, and decorative layouts.

## Primary Layout

The main window uses a sidebar and main view structure. The main view may internally use a device list, detail content, and inspector panel, but the app entry point should remain simple.

```text
Main Window
  Toolbar
  Sidebar
  Main View
    Device List
    Device Workspace
      Device Header
      Detail Content
      Inspector
```

The preferred SwiftUI composition is:

```text
ContentView
  AppEntryView
    SidebarView
    MainWorkspaceView
      DeviceListView
      DeviceDetailView
      InspectorView
```

`ContentView` should be a lightweight entry view. It should own only root-level composition and high-level state injection. It should not contain sample data, row layouts, tool panels, or inspector details in production.

## Main Window

The main window opens to the management workspace. It should have a practical minimum size large enough to keep the sidebar and main work area useful.

Recommended starting constraints:

```text
Minimum width: 1120
Minimum height: 720
Sidebar ideal width: 240
Device list ideal width: 380
Inspector width: 300-320
```

The window contains:

- Toolbar for global actions
- Sidebar for navigation and broad filtering
- Device list for simulator selection
- Workspace area for selected-device management
- Inspector panel for identifiers, paths, app metadata, and environment status

When no device is selected, the main workspace shows a quiet empty state that asks the user to select a simulator. It should not replace the sidebar or remove search and refresh controls.

## Toolbar

The toolbar exposes global and context-aware commands. Toolbar items should use icon labels and native macOS button styles.

Primary toolbar actions:

- Refresh simulator inventory
- Open Simulator.app
- Create simulator
- Clone selected simulator
- Pair watch device
- Open command palette
- Open Settings

The toolbar search field supports global search across:

- Simulator names
- Platforms
- Runtimes
- Device types
- Device UDIDs
- Installed app names
- Bundle identifiers
- Known container paths when indexed

Toolbar actions must reflect command state. If a refresh or long-running command is active, the relevant control should show a disabled or progress state to prevent duplicate execution.

## Sidebar

The sidebar is the stable navigation anchor for the main window. It groups broad simulator navigation categories rather than detailed actions.

Sidebar sections:

- Pinned
- Platforms
- Runtimes
- Device State
- Utilities

Pinned items appear first because the app is intended for repeated development workflows. Platform and runtime entries narrow the device list. State entries support quick filtering by booted, shutdown, unavailable, and other simulator states.

The Utilities section links to workspace-level tools:

- Developer Tools
- Action Log
- Link Folders
- Diagnostics
- Environment

Selecting a sidebar item updates the main workspace without changing app-wide state unrelated to navigation. If the current device is no longer visible after filtering, selection moves to the first visible device or becomes empty.

## Device List

The device list is the main selection surface. It should support many simulators without becoming card-heavy or visually noisy.

Each device row shows:

- Platform icon
- Device name
- Runtime
- Device type
- State badge
- Installed app count
- Data size when available
- Pinned indicator when applicable

Rows should be compact, keyboard navigable, and stable in height. The selected row drives the device workspace and inspector.

Device sorting options:

- Name
- State
- Runtime
- Platform
- Last booted date
- Data size

Device filtering options:

- Sidebar selection
- Global search query
- Availability
- Pinned status
- Installed app presence

Filtering should not discard the last successful simulator snapshot. It only changes the visible projection of current state.

## Device Workspace

The device workspace is the main content area for the selected simulator. It is organized around the current device context.

Workspace sections:

- Device header
- Summary metrics
- Installed apps
- Developer tools
- Recent command results

The workspace should be scrollable so dense content remains accessible on smaller window heights. The device header stays visually distinct from the scrollable content.

### Device Header

The device header confirms the active simulator context and exposes the most common selected-device actions.

Header content:

- Platform icon
- Device name
- State badge
- Runtime
- UDID
- Boot action
- Open Simulator.app action
- Shutdown action
- More actions menu when needed

Action availability depends on device state:

- Boot is disabled for already booted devices.
- Shutdown is disabled for non-booted devices.
- Actions are disabled for unavailable devices unless the action can still work.
- Disabled controls should expose a reason through help text or command validation feedback.

### Summary Metrics

Summary metrics give quick context before the user scrolls into detailed tools.

Recommended metrics:

- Platform
- Runtime
- Installed apps
- Data size
- Availability
- Last booted date

Metrics should be compact panels with 8 px corner radius or less. They are informational and should not visually compete with primary actions.

### Installed Apps

Installed apps are shown inside the selected device context. This section should support both quick action and inspection.

Each app row shows:

- App icon or fallback symbol
- Display name
- Bundle identifier
- Version and build
- Data size when calculated
- Launch action
- Open container action

Selecting an app updates the inspector. App actions operate on the selected simulator and app pair.

Common app actions:

- Launch
- Terminate
- Uninstall
- Reset sandbox
- Open bundle container
- Open data container
- Open App Group container
- Copy bundle identifier
- Install onto another compatible simulator

Destructive actions must require confirmation. They should not be placed as prominent default actions in the row.

### Developer Tools

Developer tools are grouped as selected-device utilities. They should appear as compact tool tiles or rows depending on available width.

Tools:

- Deep Link
- Push Notification
- Privacy Permissions
- Location
- Status Bar Override
- Screenshot
- Video Recording
- Device Logs
- Storage Analysis
- Diagnostics Export

Tool tiles open focused editors or sheets. They should not run commands immediately unless the action is unambiguous and safe.

### Recent Command Results

Recent command results provide feedback without interrupting the workflow.

Each command result shows:

- Success or failure icon
- Command summary
- Target context
- Duration
- Timestamp when space allows

Failures should preserve:

- Executable
- Arguments
- Standard error
- Exit code
- Recovery context

The action log can provide a full history view. The workspace section should stay compact and show recent relevant results.

## Inspector

The inspector is a persistent secondary panel for exact identifiers, paths, environment state, and selected app details.

Inspector groups:

- Device
- Folders
- Selected App
- App Groups
- Environment
- Warnings

Device group:

- State
- Runtime
- Device type
- UDID
- Availability
- Pairing state where relevant

Folders group:

- Device data path
- Device log path
- Link folder path when enabled

Selected App group:

- Display name
- Bundle identifier
- Version
- Build
- Bundle container
- Data container
- App Group containers

Environment group:

- Active Xcode path
- Xcode version
- `simctl` availability
- Snapshot freshness
- Last refresh time

Path rows should provide open and copy controls. Path text should support selection.

## Search and Selection Behavior

Search is global within the main window. It filters the visible device list and may highlight installed app matches in the selected-device workspace.

Search behavior:

1. Empty search shows the sidebar-filtered device list.
2. Device matches keep the matching device visible.
3. App matches keep the containing device visible.
4. Bundle identifier matches select or reveal the app when possible.
5. UDID matches select or reveal the device when possible.

Selection rules:

- Preserve selected device across refresh when the device still exists.
- Preserve selected app across refresh when the app still exists on the selected device.
- If the selected device disappears, move selection to a nearby valid device or clear selection.
- If filtering hides the selected device, move selection to the first visible device.
- Never show stale inspector details for a missing selected target.

## Empty and Error States

Empty and error states should preserve navigation context. The app should not replace the whole window with a blocking error screen unless the app cannot render.

Expected states:

- No simulators found
- No installed apps discovered
- Xcode path unavailable
- `simctl` unavailable
- Refresh failed with stale snapshot available
- Permission denied for CoreSimulator paths
- Container path unavailable
- Command failed

Refresh failure should keep the last successful snapshot visible and mark it stale. Error details should include command output when available.

## Menu Bar Relationship

The menu bar interface is a compact surface for quick actions. It should use the same state and action layer as the main window but not duplicate the full workspace.

Menu bar content:

- Current status
- Refresh
- Open SimControl
- Open Simulator.app
- Pinned devices
- Recent devices
- Device actions
- Installed app actions
- Settings
- Quit SimControl

The menu bar should render from cached state. Opening the menu must not trigger expensive simulator scans.

## Visual Style

The UI should feel like a focused macOS developer tool.

Style direction:

- Native SwiftUI controls where possible
- Sidebar list style for navigation
- Dense list rows for simulator inventory
- Compact panels for summaries and grouped details
- 8 px or smaller corner radius for panels
- Restrained color use for status and app/tool identity
- System symbols for actions and categories
- Clear disabled states for unavailable actions

Avoid:

- Landing-page composition
- Decorative hero sections
- Nested cards
- Large marketing-style panels
- Full-screen empty states that remove navigation
- One-color theme dominance
- Decorative gradients or background effects

## Accessibility and Keyboard Support

The main window should be usable with keyboard and assistive technologies.

Required support:

- Keyboard selection in the device list
- Search focus shortcut
- Refresh shortcut
- Settings shortcut
- Command palette shortcut
- Accessible labels for icon-only buttons
- VoiceOver labels for state badges
- Text selection for UDIDs, bundle identifiers, and paths
- Clear focus order from sidebar to list to workspace to inspector

Interactive rows should have full-row hit targets. Icon-only buttons must have help text or accessibility labels.

## Implementation Boundaries

The prototype may keep sample layout in one file while the UI direction is being evaluated. Production implementation should be split by responsibility.

Recommended files:

```text
SimControl/
  ContentView.swift
  AppEntryView.swift
  SidebarView.swift
  MainWorkspaceView.swift
  DeviceListView.swift
  DeviceRow.swift
  DeviceDetailView.swift
  DeviceHeaderView.swift
  InstalledAppsView.swift
  DeveloperToolsView.swift
  CommandResultsView.swift
  InspectorView.swift
```

`ContentView` should:

- Compose the app entry view.
- Inject shared store dependencies.
- Hold no simulator sample data.
- Hold no detailed row or panel rendering.

Feature views should:

- Receive derived state from `SimulatorStore`.
- Send user intent back to the store through explicit actions.
- Avoid direct shell execution.
- Avoid direct CoreSimulator file scanning.
- Avoid parsing `simctl` output.

The store remains responsible for selection, filters, action state, command results, and stale snapshot handling. Views render the current state and expose user intent.

## Future Refinements

Near-term UI refinements:

- Replace sample data with `SimulatorSnapshot`.
- Add persistent selected-device and selected-app restoration.
- Add real command-state disabled reasons.
- Add settings scene for environment and menu bar preferences.
- Add full action log view.
- Add command palette.
- Add confirmation sheets for destructive actions.
- Add menu bar extra using the same store actions.

The layout should stay stable while these features are added. New functionality should extend the existing sidebar, workspace, and inspector structure rather than introducing unrelated navigation patterns.
