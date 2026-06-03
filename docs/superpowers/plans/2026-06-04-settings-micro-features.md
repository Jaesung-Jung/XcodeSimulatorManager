# Settings Micro Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the store-backed Settings scene into six smaller Swift Package feature targets while keeping `SettingsFeature` as the root scene feature.

**Architecture:** Each section target owns a tiny TCA reducer, state, action, and SwiftUI view. `SettingsFeature` composes those child reducers, maps loaded `SimControlUserSettings` into child state, aggregates child state back into `SimControlUserSettings`, and remains the only Settings feature that uses `UserSettingsClient`.

**Tech Stack:** Swift Package Manager, SwiftUI, TCA, Swift Testing, `scripts/verify-modularization.sh`.

---

### Task 1: Define child feature target contracts with RED tests

**Files:**
- Modify: `Packages/SimControlModules/Package.swift`
- Create: `Packages/SimControlModules/Tests/GeneralSettingsFeatureTests/GeneralSettingsFeatureTests.swift`
- Create: `Packages/SimControlModules/Tests/MenuBarSettingsFeatureTests/MenuBarSettingsFeatureTests.swift`
- Create: `Packages/SimControlModules/Tests/SafetySettingsFeatureTests/SafetySettingsFeatureTests.swift`
- Create: `Packages/SimControlModules/Tests/XcodeSettingsFeatureTests/XcodeSettingsFeatureTests.swift`
- Create: `Packages/SimControlModules/Tests/LinkFolderSettingsFeatureTests/LinkFolderSettingsFeatureTests.swift`
- Create: `Packages/SimControlModules/Tests/DiagnosticsSettingsFeatureTests/DiagnosticsSettingsFeatureTests.swift`

- [x] **Step 1: Add package products, targets, and test targets**

Add these products:

```swift
.library(name: "GeneralSettingsFeature", targets: ["GeneralSettingsFeature"]),
.library(name: "MenuBarSettingsFeature", targets: ["MenuBarSettingsFeature"]),
.library(name: "SafetySettingsFeature", targets: ["SafetySettingsFeature"]),
.library(name: "XcodeSettingsFeature", targets: ["XcodeSettingsFeature"]),
.library(name: "LinkFolderSettingsFeature", targets: ["LinkFolderSettingsFeature"]),
.library(name: "DiagnosticsSettingsFeature", targets: ["DiagnosticsSettingsFeature"]),
```

Each child target depends only on `ComposableArchitecture`.

- [x] **Step 2: Write RED tests for one reducer/view contract per child**

Each test imports its child module and constructs `Store(initialState:) { ChildFeature() }`, then sends the child setting change action through `TestStore`.

- [x] **Step 3: Run child feature tests to verify failure**

```bash
swift test --package-path Packages/SimControlModules --filter GeneralSettingsFeatureTests
```

Expected: FAIL because `GeneralSettingsFeature` source does not exist yet. Repeat for the other child feature filters or run all six filters after source paths are declared.

### Task 2: Implement child feature targets

**Files:**
- Create: `Packages/SimControlModules/Sources/GeneralSettingsFeature/GeneralSettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/GeneralSettingsFeature/GeneralSettingsView.swift`
- Create: `Packages/SimControlModules/Sources/MenuBarSettingsFeature/MenuBarSettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/MenuBarSettingsFeature/MenuBarSettingsView.swift`
- Create: `Packages/SimControlModules/Sources/SafetySettingsFeature/SafetySettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/SafetySettingsFeature/SafetySettingsView.swift`
- Create: `Packages/SimControlModules/Sources/XcodeSettingsFeature/XcodeSettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/XcodeSettingsFeature/XcodeSettingsView.swift`
- Create: `Packages/SimControlModules/Sources/LinkFolderSettingsFeature/LinkFolderSettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/LinkFolderSettingsFeature/LinkFolderSettingsView.swift`
- Create: `Packages/SimControlModules/Sources/DiagnosticsSettingsFeature/DiagnosticsSettingsFeature.swift`
- Create: `Packages/SimControlModules/Sources/DiagnosticsSettingsFeature/DiagnosticsSettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/GeneralSettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/MenuBarSettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/SafetySettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/XcodeSettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/LinkFolderSettingsView.swift`
- Delete: `Packages/SimControlModules/Sources/SettingsFeature/DiagnosticsSettingsView.swift`

- [x] **Step 1: Add child reducers**

Each child reducer owns one `State` property and one setting-change `Action`.

- [x] **Step 2: Move child views into child targets**

Each child view receives `StoreOf<ChildFeature>` and keeps the same SwiftUI controls that currently exist in `SettingsFeature`.

- [x] **Step 3: Run child feature tests**

```bash
swift test --package-path Packages/SimControlModules --filter SettingsFeatureTests
```

Expected at this point: root tests may fail until Task 3 rewires `SettingsFeature`, while child feature filters should pass.

### Task 3: Rewire root SettingsFeature composition

**Files:**
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/SettingsFeature.swift`
- Modify: `Packages/SimControlModules/Sources/SettingsFeature/SettingsRootView.swift`
- Modify: `Packages/SimControlModules/Tests/SettingsFeatureTests/SettingsFeatureSmokeTests.swift`
- Modify: `Packages/SimControlModules/Package.swift`

- [x] **Step 1: Update root target dependencies**

`SettingsFeature` depends on the six child feature targets, `SimControlClients`, and `ComposableArchitecture`.

- [x] **Step 2: Replace flat root state with child states**

`SettingsFeature.State` stores `general`, `menuBar`, `safety`, `xcode`, `linkFolder`, `diagnostics`, and `isLoading`. It keeps a computed `settings` get/set contract so existing tests and callers can still reason about the full settings value.

- [x] **Step 3: Scope root actions into child actions**

`SettingsFeature.Action` contains `.general(GeneralSettingsFeature.Action)`, `.menuBar(MenuBarSettingsFeature.Action)`, `.safety(SafetySettingsFeature.Action)`, `.xcode(XcodeSettingsFeature.Action)`, `.linkFolder(LinkFolderSettingsFeature.Action)`, `.diagnostics(DiagnosticsSettingsFeature.Action)`, `.task`, and `.settingsLoaded`.

- [x] **Step 4: Persist after child changes**

Root reducer composes child reducers first, then saves `state.settings` for each child setting-change action.

- [x] **Step 5: Scope child stores in `SettingsRootView`**

Each section receives `store.scope(state: \.child, action: \.child)`.

### Task 4: Strengthen boundaries, docs, and verification

**Files:**
- Modify: `scripts/verify-modularization.sh`
- Modify: `docs/architecture/isowords-inspired-modularization.md`
- Modify: `docs/plans/2026-06-04-isowords-inspired-modularization-work-plan.md`

- [x] **Step 1: Add child feature source directories to boundary checks**

All six child targets are part of `FEATURE_SOURCES`. Add a Settings child check that prevents child targets from importing root scene features, live clients, or infrastructure.

- [x] **Step 2: Update architecture docs**

Document that Settings now consists of six leaf settings feature targets plus the root `SettingsFeature` scene target.

- [x] **Step 3: Run final verification**

```bash
swift test --package-path Packages/SimControlModules --filter SettingsFeatureTests
scripts/verify-modularization.sh
git diff --check
git status --short -- .gitignore
```

Expected: all commands pass and `.gitignore` remains untouched.
