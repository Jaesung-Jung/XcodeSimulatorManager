# Xcode Simulator Control

Xcode Simulator Control is a macOS app for inspecting and operating the simulator runtimes and simulator devices available to the active Xcode installation. It focuses first on local simulator inventory and device operations, while runtime acquisition is a later concern.

## Language

**Simulator Runtime**:
An installed platform runtime that simulator devices can be created from, such as iOS, watchOS, tvOS, or visionOS.
_Avoid_: Runtime download, SDK

**Supported Platform**:
A simulator platform treated as a first-class product target: iOS, watchOS, tvOS, or visionOS.
_Avoid_: OS, SDK platform

**Device Type**:
A simulator model template that can be combined with a simulator runtime to create a simulator device.
_Avoid_: Device model, simulator model

**Simulator Device**:
A simulator instance created from a device type and a simulator runtime.
_Avoid_: Simulator, emulator

**Simulator Device Name**:
A human-readable label for a simulator device, generated from device type and runtime unless the user changes it.
_Avoid_: Identifier, UDID

**Device Inventory**:
The device-centered list of simulator devices available from the active Xcode.
_Avoid_: Runtime list, simulator list

**Device Operation**:
A user-initiated action that changes a simulator device's lifecycle, data, or existence.
_Avoid_: Device management

**Destructive Device Operation**:
A device operation that removes a simulator device or erases its contents.
_Avoid_: Dangerous action

**Device Pairing**:
A relationship between simulator devices that lets platform companions operate together, such as an iPhone and Apple Watch simulator.
_Avoid_: Watch pairing, pair management

**Target App**:
An app bundle installed on and launched inside a simulator device.
_Avoid_: App, application

**Target App Bundle**:
A built `.app` bundle selected by the user as the installable input for a target app.
_Avoid_: IPA, archive, project

**Runtime Acquisition**:
The later-stage capability of downloading, installing, or deleting simulator runtimes.
_Avoid_: Runtime management

**Log Inspection**:
The later-stage capability of streaming, searching, or analyzing logs from simulator devices or target apps.
_Avoid_: Logging

**Menu Bar Control**:
The later-stage capability of operating simulator devices from a macOS menu bar item while the main window is closed.
_Avoid_: Quit-time control, background simulator control

**Active Xcode**:
The Xcode installation selected by the system developer directory and used as the app's source of simulator truth.
_Avoid_: Selected Xcode, Xcode version

## Relationships

- The app reads simulator state from exactly one **Active Xcode**.
- The **Device Inventory** is organized around **Simulator Devices**, with **Simulator Runtimes** used for grouping and filtering.
- A **Supported Platform** determines first-class filtering and device creation behavior.
- A **Device Type** and a **Simulator Runtime** are selected together to create a **Simulator Device**.
- A **Simulator Runtime** can support zero or more **Simulator Devices**.
- A **Simulator Device** belongs to exactly one **Simulator Runtime**.
- A **Simulator Device Name** does not identify a **Simulator Device**; duplicate proposed names are automatically numbered.
- A **Device Operation** applies to one or more **Simulator Devices**.
- A **Destructive Device Operation** requires confirmation before execution.
- A **Device Pairing** relates two or more **Simulator Devices** and is displayed but not changed in the first version.
- A **Target App Bundle** produces one **Target App** installation on a **Simulator Device**.
- A **Target App** can be launched from a **Simulator Device**.
- **Runtime Acquisition** is outside the initial product scope.
- **Log Inspection** is outside the initial product scope.
- **Menu Bar Control** is outside the initial product scope.

## Example dialogue

> **Dev:** "Should the first version let users install a missing iOS runtime?"
> **Domain expert:** "No. The first version should show installed **Simulator Runtimes** from the **Active Xcode** and manage **Simulator Devices**. **Runtime Acquisition** comes later."
>
> **Dev:** "When we say app launch, do we mean launching Xcode Simulator Control itself?"
> **Domain expert:** "No. A **Target App** is installed on and launched inside a **Simulator Device**. **Log Inspection** is not part of the first version."
>
> **Dev:** "Should users be able to point the app at an Xcode project?"
> **Domain expert:** "No. The user provides a built **Target App Bundle**. Building projects, extracting archives, and installing IPAs are outside the first version."
>
> **Dev:** "Should the main screen start from runtimes or devices?"
> **Domain expert:** "Start from the **Device Inventory**. Users operate **Simulator Devices** directly, while **Simulator Runtimes** help them filter and understand compatibility."
>
> **Dev:** "What happens if the generated device name already exists?"
> **Domain expert:** "The app appends a number to the proposed **Simulator Device Name**. The unique identity still comes from the device UDID."
>
> **Dev:** "Should users create a new iPhone and Apple Watch pair in the first version?"
> **Domain expert:** "No. Show existing **Device Pairing** relationships and warnings, but leave pairing creation and edits for a later version."
>
> **Dev:** "Can a booted simulator be deleted from the app?"
> **Domain expert:** "Yes, but deleting it is a **Destructive Device Operation**. The app should confirm that it will shut the device down before deleting it."
>
> **Dev:** "Should users operate simulators after closing the main window?"
> **Domain expert:** "No. **Menu Bar Control** is a later-stage capability and is not part of the first version."

## Flagged ambiguities

- "Runtime management" could mean either inspecting installed **Simulator Runtimes** or performing **Runtime Acquisition**. Resolved: initial scope includes inspection only; acquisition is deferred.
- "Xcode selection" could mean browsing multiple installed Xcodes or using the system-selected toolchain. Resolved: the app uses the **Active Xcode** only.
- "App" could mean this macOS product or an app installed into a simulator. Resolved: use **Target App** for simulator-installed apps.
- "Install app" could mean installing a bundle, IPA, archive output, or building a project. Resolved: the first version installs only a **Target App Bundle**.
- "Simulator list" could mean runtimes, device types, or created devices. Resolved: use **Device Inventory** for the created-device list.
- "Device name" could be mistaken for identity. Resolved: **Simulator Device Name** is only a label; UDID remains the unique identity.
- "Watch pairing" is too narrow because companion relationships may apply beyond watchOS. Resolved: use **Device Pairing**.
- "Delete" and "erase" both remove user-visible state, but at different scopes. Resolved: both are **Destructive Device Operations** and require confirmation.
- "App termination" could mean closing the main window or quitting the process. Resolved: first version has no **Menu Bar Control**; quitting the app ends simulator control.
