# SettingsFeature Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `SettingsFeature` from static SwiftUI placeholders into a store-backed TCA feature with a user settings dependency boundary.

**Architecture:** `SimControlClients` owns `UserSettingsClient` and the serializable `SimControlUserSettings` value. `SimControlClientsLive` owns a `UserDefaults` backed live adapter. `SettingsFeature` owns `State`, `Action`, reducer logic, and SwiftUI views that read/write settings through the injected client. The app target creates a `settingsStore` in `AppContainer`.

**Tech Stack:** Swift Package Manager, SwiftUI, TCA, swift-dependencies, UserDefaults, Swift Testing.

---

### Task 1: RED tests for settings client and feature reducer

**Files:**
- Modify: `Packages/SimControlModules/Tests/SettingsFeatureTests/SettingsFeatureSmokeTests.swift`

- [x] **Step 1: Replace the static-view smoke test with store-backed tests**

```swift
import ComposableArchitecture
import SettingsFeature
import SimControlClients
import Testing

@Suite
@MainActor
struct SettingsFeatureSmokeTests {
  @Test func rootViewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    }

    _ = SettingsRootView(store: store)
  }

  @Test func taskLoadsUserSettings() async {
    let settings = SimControlUserSettings(
      launchesAtLogin: true,
      showsMenuBarExtra: false,
      confirmsDestructiveActions: false,
      preferredXcodeDeveloperPath: "/Applications/Xcode-beta.app/Contents/Developer",
      linkFolderPath: "/tmp/simcontrol-links",
      enablesDiagnostics: true
    )

    let store = TestStore(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings.load = { settings }
    }

    await store.send(.task) {
      $0.isLoading = true
    }
    await store.receive(.settingsLoaded(settings)) {
      $0.isLoading = false
      $0.settings = settings
    }
  }
}
```

- [x] **Step 2: Run test to verify it fails**

```bash
swift test --package-path Packages/SimControlModules --filter SettingsFeatureTests
```

Expected: compile failure because `SettingsFeature.State`, `SettingsFeature.Action`, `SimControlUserSettings`, and `UserSettingsClient` do not exist.

### Task 2: Add UserSettingsClient and live adapter

**Files:**
- Create: `Packages/SimControlModules/Sources/SimControlClients/UserSettingsClient/UserSettingsClient.swift`
- Create: `Packages/SimControlModules/Sources/SimControlClientsLive/UserSettingsClient+Live.swift`
- Modify: `Packages/SimControlModules/Package.swift`

- [x] **Step 1: Add the settings model and client**

`SimControlUserSettings` stores the first app-level settings that are visible in the existing Settings sections:

- launch behavior
- menu bar visibility
- destructive confirmation preference
- preferred Xcode developer path
- link folder path
- diagnostics toggle

- [x] **Step 2: Add `UserDefaults` live implementation**

The live adapter encodes/decodes `SimControlUserSettings` as JSON data under a single key. Missing or invalid stored data returns `.defaults`.

- [x] **Step 3: Add package dependencies**

`SettingsFeature` depends on `SimControlClients` and TCA. `SettingsFeatureTests` depends on `SimControlClients` and TCA. `SimControlClientsLive` already depends on `SimControlClients`.

### Task 3: Add SettingsFeature reducer and store-backed views

**Files:**
- Create: `Packages/SimControlModules/Sources/SettingsFeature/SettingsFeature.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/SettingsRootView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/GeneralSettingsView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/MenuBarSettingsView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/SafetySettingsView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/XcodeSettingsView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/LinkFolderSettingsView.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/DiagnosticsSettingsView.swift`

- [x] **Step 1: Add reducer state and actions**

State contains `settings` and `isLoading`. Actions include `.task`, `.settingsLoaded`, and one action per editable setting.

- [x] **Step 2: Save changes through the client**

Each setting-change action mutates state and returns a `.run` effect that calls `userSettings.save(state.settings)`.

- [x] **Step 3: Replace placeholder views**

`SettingsRootView` receives `StoreOf<SettingsFeature>`, runs `.task`, and renders the six section views. Section views receive a store and send setting-change actions from SwiftUI controls.

### Task 4: Wire SettingsFeature into the app target

**Files:**
- Modify: `SimControl/App/AppContainer.swift`
- Modify: `SimControl/App/SimControlApp.swift`

- [x] **Step 1: Create `settingsStore`**

`AppContainer` owns `let settingsStore: StoreOf<SettingsFeature>` and injects `$0.userSettings = .live()`.

- [x] **Step 2: Inject settings store into the Settings scene**

`SimControlApp` renders `SettingsRootView(store: appContainer.settingsStore)`.

### Task 5: Boundary checks, docs, verification, commit

**Files:**
- Modify: `scripts/verify-modularization.sh`
- Modify: `docs/architecture/isowords-inspired-modularization.md`
- Modify: `docs/plans/2026-06-04-isowords-inspired-modularization-work-plan.md`

- [x] **Step 1: Strengthen Settings boundary checks**

Ensure `SettingsFeature` cannot import `SimControlClientsLive` or `SimControlInfrastructure`; this is already partly covered by the feature rule, and the docs should state it explicitly.

- [x] **Step 2: Run verification**

```bash
swift test --package-path Packages/SimControlModules --filter SettingsFeatureTests
scripts/verify-modularization.sh
git diff --check
git status --short -- .gitignore
```

Expected: all commands succeed and `.gitignore` is not modified.
