# MenuBarFeature Independence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `MenuBarFeature` a real independent feature target that no longer imports `MainWindowFeature`.

**Architecture:** `MenuBarFeature` owns its own `State`, `Action`, reducer, and SwiftUI views. `MainWindowFeature` derives menu bar state from `WorkspaceFeature.State`, scopes its store to `MenuBarFeature`, and interprets menu bar actions by delegating to existing refresh, simulator app, and workspace selection flows.

**Tech Stack:** Swift Package Manager, SwiftUI, TCA, Swift Testing, existing modularization boundary script.

---

### Task 1: RED test for independent menu bar construction

**Files:**
- Modify: `Packages/SimControlModules/Tests/MenuBarFeatureTests/MenuBarFeatureTests.swift`

- [x] **Step 1: Write the failing test**

```swift
import ComposableArchitecture
import MenuBarFeature
import Testing

@Suite
@MainActor
struct MenuBarFeatureTests {
  @Test func rootViewCanBeConstructedWithoutMainWindowFeature() {
    let store = Store(initialState: MenuBarFeature.State()) {
      MenuBarFeature()
    }

    _ = MenuBarRootView(store: store)
  }
}
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --package-path Packages/SimControlModules --filter MenuBarFeatureTests
```

Expected: compile failure because `MenuBarFeature.State` and reducer do not exist yet.

### Task 2: Add menu bar state/action/reducer and view wiring

**Files:**
- Create: `Packages/SimControlModules/Sources/MenuBarFeature/MenuBarFeature.swift`
- Modify: `Packages/SimControlModules/Sources/MenuBarFeature/MenuBarRootView.swift`
- Modify: `Packages/SimControlModules/Sources/MenuBarFeature/MenuBarAppActionsView.swift`
- Modify: `Packages/SimControlModules/Sources/MenuBarFeature/MenuBarDeviceSection.swift`
- Modify: `Packages/SimControlModules/Package.swift`

- [x] **Step 1: Implement menu bar API**

```swift
@Reducer
public struct MenuBarFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState
    public var filters: SimulatorFilters

    public init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      filters: SimulatorFilters = SimulatorFilters()
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.filters = filters
    }

    public init(workspace: WorkspaceFeature.State) {
      self.init(
        snapshot: workspace.snapshot,
        refreshState: workspace.refreshState,
        filters: workspace.filters
      )
    }
  }

  public enum Action: Equatable {
    case presented(at: Date)
    case refreshButtonTapped
    case openSimulatorAppButtonTapped
    case deviceSelected(String)
    case appSelected(deviceID: String, appID: String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
```

- [x] **Step 2: Update views**

Change view stores from `StoreOf<MainWindowFeature>` to `StoreOf<MenuBarFeature>`. Replace direct `MainWindowFeature.Action` sends with `MenuBarFeature.Action` sends.

- [x] **Step 3: Remove package dependency**

Remove `"MainWindowFeature"` from the `MenuBarFeature` target dependencies.

- [x] **Step 4: Verify focused test passes**

Run:

```bash
swift test --package-path Packages/SimControlModules --filter MenuBarFeatureTests
```

Expected: PASS.

### Task 3: Route menu bar actions through MainWindowFeature

**Files:**
- Modify: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature.swift`
- Modify: `SimControl/App/SimControlApp.swift`
- Modify: `Packages/SimControlModules/Tests/MainWindowFeatureTests/MainWindowFeatureTests.swift`
- Modify: `Packages/SimControlModules/Package.swift`

- [x] **Step 1: Add `MainWindowFeature.State.menuBar` projection**

```swift
public var menuBar: MenuBarFeature.State {
  get { MenuBarFeature.State(workspace: workspace) }
  set {}
}
```

- [x] **Step 2: Add `MainWindowFeature.Action.menuBar`**

```swift
case menuBar(MenuBarFeature.Action)
```

- [x] **Step 3: Route menu actions**

```swift
case .menuBar(.presented(let date)):
  return autoRefreshFromMenuBar(&state, at: date)
case .menuBar(.refreshButtonTapped):
  return refresh(&state)
case .menuBar(.openSimulatorAppButtonTapped):
  return openSimulatorApp(&state)
case .menuBar(.deviceSelected(let deviceID)):
  state.workspace.selectDevice(id: deviceID)
  return .none
case .menuBar(.appSelected(let deviceID, let appID)):
  state.workspace.selectDevice(id: deviceID)
  state.workspace.selectApp(id: appID)
  return .none
```

- [x] **Step 4: Scope app scene store**

```swift
MenuBarRootView(
  store: appContainer.mainWindowStore.scope(
    state: \.menuBar,
    action: \.menuBar
  )
)
```

- [x] **Step 5: Verify focused tests pass**

Run:

```bash
swift test --package-path Packages/SimControlModules --filter 'MenuBarFeatureTests|MainWindowFeatureTests'
```

Expected: PASS.

### Task 4: Enforce the new boundary

**Files:**
- Modify: `scripts/verify-modularization.sh`
- Modify: `docs/architecture/isowords-inspired-modularization.md`
- Modify: `docs/plans/2026-06-04-isowords-inspired-modularization-work-plan.md`

- [x] **Step 1: Add `MenuBarFeature -> MainWindowFeature` import ban**

The existing feature import rule already bans `SimControlInfrastructure` and `SimControlClientsLive`; add a specific check that `MenuBarFeature` cannot import `MainWindowFeature`.

- [x] **Step 2: Update architecture docs**

Document `MenuBarFeature` as an independent scene feature that reports actions to `MainWindowFeature` through store scoping rather than importing it.

- [x] **Step 3: Run full verification**

Run:

```bash
scripts/verify-modularization.sh
git diff --check
git status --short -- .gitignore
```

Expected: verification succeeds and `.gitignore` is not modified.
