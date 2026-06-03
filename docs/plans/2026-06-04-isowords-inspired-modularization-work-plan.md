# isowords 기반 SimControl 모듈화 작업 플랜

> **작업 에이전트 지침:** 이 계획을 구현할 때는 task 단위로 진행하고, 각 task 완료 후 `swift test` 또는 `xcodebuild test`로 검증한다. 큰 파일 이동은 한 번에 하지 말고 package target 단위로 작게 나눈다.

**목표:** SimControl을 Swift Package 기반 모듈 구조로 전환하고, `MainWindowFeature` 중심의 과도한 orchestration을 feature/client/workflow 경계로 분리한다.

**아키텍처:** isowords의 feature target, dependency client, live/test key 분리 패턴을 SimControl 규모에 맞게 축약 적용한다. 초기에는 `Packages/SimControlModules` local package를 사용하고, app target은 live dependency composition root로 유지한다.

**기술 스택:** Swift Package Manager, SwiftUI, TCA, swift-dependencies `@DependencyClient`, Swift Testing, Xcode project local package dependency.

---

## 현재 구현 상태

2026-06-04 기준 1차 작업은 다음 범위까지 완료했다.

- `Packages/SimControlModules` local package 생성.
- `SimControlDomain`, `SimControlInfrastructure`, `SimControlClients`, `SimControlClientsLive` target 구성.
- `MainWindowWorkflows` target으로 command orchestration 분리.
- `MainWindowFeature` target으로 main window reducer/view/menu bar/shared UI 이동.
- `SettingsFeature` target으로 settings scene view 이동.
- `MainWindowFeatureTests`를 package test target으로 이동.
- app target은 `AppContainer`, scene 선언, app delegate, asset 중심으로 축소.
- 책임 없는 app target placeholder였던 `Services/`와 `State/` 제거.
- 반복 검증 스크립트 `scripts/verify-modularization.sh` 추가.

남은 후속 작업은 `MenuBarFeature`, `SimControlSharedUI`의 독립 target 분리와 root package 전환 여부 결정이다. root package 전환은 현재 local package 구조가 안정된 뒤 선택한다.

## 전체 작업 순서

1. Package skeleton 생성.
2. Domain model 이동.
3. Inventory query/projection 순수화.
4. Infrastructure 이동.
5. Dependency client/live/test 분리.
6. Workflow client 추출.
7. Feature target 이동.
8. App target composition root 정리.
9. Preview/resource/localization 정리.
10. Root package 전환 여부 결정.

## Task 1: Baseline 확인과 package skeleton 생성

**파일:**

- 생성: `Packages/SimControlModules/Package.swift`
- 생성: `Packages/SimControlModules/Sources/SimControlDomain/Module.swift`
- 생성: `Packages/SimControlModules/Tests/SimControlDomainTests/ModuleTests.swift`
- 수정: `SimControl.xcodeproj/project.pbxproj`

**작업:**

- `SimControlModules` package를 만든다.
- 최소 target은 `SimControlDomain`과 `SimControlDomainTests`만 둔다.
- Xcode project에 local package dependency를 추가한다.

**초기 Package.swift 형태:**

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SimControlModules",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SimControlDomain", targets: ["SimControlDomain"])
  ],
  dependencies: [],
  targets: [
    .target(name: "SimControlDomain"),
    .testTarget(
      name: "SimControlDomainTests",
      dependencies: ["SimControlDomain"]
    )
  ]
)
```

**검증:**

```bash
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 2: Domain model을 package로 이동

**파일:**

- 이동: `SimControl/Domain/*.swift` -> `Packages/SimControlModules/Sources/SimControlDomain/`
- 이동: `SimControl/State/SimulatorFilters.swift` -> `Packages/SimControlModules/Sources/SimControlDomain/SimulatorFilters.swift`
- 이동: `SimControlTests/Domain/*Tests.swift` -> `Packages/SimControlModules/Tests/SimControlDomainTests/`
- 수정: app/test import statements

**작업:**

- domain model을 `public` contract로 정리한다.
- package 외부에서 필요한 initializer/property/method만 `public`으로 표시한다.
- `SimulatorFilters`는 UI state라기보다 inventory query input이므로 domain target으로 이동한다.

**주의:**

- `public`은 module 밖에서 필요한 항목에만 붙인다.
- public type과 method에는 `///` 문서를 추가한다.
- `SimControlDomain`은 `Foundation` 외 의존성을 갖지 않는다.

**검증:**

```bash
rg "import SwiftUI|import ComposableArchitecture" Packages/SimControlModules/Sources/SimControlDomain
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

`rg` 명령은 결과가 없어야 한다.

## Task 3: Inventory query와 selection reconciliation 추출

**파일:**

- 생성: `Packages/SimControlModules/Sources/SimControlDomain/SimulatorInventoryQuery.swift`
- 생성: `Packages/SimControlModules/Sources/SimControlDomain/SimulatorInventorySelection.swift`
- 생성: `Packages/SimControlModules/Tests/SimControlDomainTests/SimulatorInventoryQueryTests.swift`
- 수정: `SimControl/Features/MainWindow/Features/WorkspaceFeature.swift`
- 수정: `SimControlTests/Features/MainWindow/WorkspaceFeatureTests.swift`

**추출 대상:**

- device filtering.
- device sorting.
- app filtering.
- app sorting.
- exact search target lookup.
- valid selected device/app ID reconciliation.
- selected runtime/device type/pair summary 계산.
- compatible install target count.

**권장 API:**

```swift
public struct SimulatorInventoryQuery: Equatable {
  public var snapshot: SimulatorSnapshot
  public var filters: SimulatorFilters

  public func visibleDevices() -> [SimulatorDevice]
  public func visibleApps(for deviceID: SimulatorDevice.ID) -> [InstalledApp]
  public func exactSearchTarget() -> SimulatorInventorySelection
}
```

**검증:**

```bash
swift test --package-path Packages/SimControlModules --filter SimulatorInventoryQueryTests
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 4: Infrastructure target 생성과 DTO 이동

**파일:**

- 수정: `Packages/SimControlModules/Package.swift`
- 생성 target: `SimControlInfrastructure`
- 이동: `SimControl/Services/Models/*.swift` -> `Packages/SimControlModules/Sources/SimControlInfrastructure/Models/`
- 이동: `SimControl/Services/CommandExecutor.swift`
- 이동: `SimControl/Services/CoreSimulatorService.swift`
- 이동: `SimControl/Services/AppContainerScanner.swift`
- 이동: `SimControl/Services/PathActionService.swift`
- 이동: `SimControl/Services/AppSandboxResetService.swift`
- 이동: `SimControl/Repositories/SimulatorRepository.swift`
- 이동: `SimControlTests/Services`와 `SimControlTests/Repositories`의 관련 test

**Package target 추가 예시:**

```swift
.library(name: "SimControlInfrastructure", targets: ["SimControlInfrastructure"])
```

```swift
.target(
  name: "SimControlInfrastructure",
  dependencies: ["SimControlDomain"]
),
.testTarget(
  name: "SimControlInfrastructureTests",
  dependencies: ["SimControlInfrastructure"]
)
```

**규칙:**

- `SimControlInfrastructure`는 `Foundation`과 `SimControlDomain`만 기본 의존성으로 둔다.
- TCA dependency client 파일은 아직 옮기지 않는다.
- `CoreSimulatorServiceClient` 같은 client 파일은 다음 task에서 처리한다.

**검증:**

```bash
rg "import SwiftUI|import ComposableArchitecture" Packages/SimControlModules/Sources/SimControlInfrastructure
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

`rg` 명령은 결과가 없어야 한다.

## Task 5: Dependency client target 생성

**파일:**

- 수정: `Packages/SimControlModules/Package.swift`
- 생성 target: `SimControlClients`
- 이동/리팩터링: `CoreSimulatorServiceClient.swift` -> `CoreSimulatorClient/Client.swift`
- 이동/리팩터링: `SimulatorRepositoryClient.swift` -> `SimulatorRepositoryClient/Client.swift`
- 이동/리팩터링: `PathActionClient.swift` -> `PathActionClient/Client.swift`
- 이동/리팩터링: `AppSandboxResetClient.swift` -> `AppSandboxResetClient/Client.swift`

**isowords식 파일 구조:**

```text
Sources/SimControlClients/
  CoreSimulatorClient/
    Client.swift
    TestKey.swift
  SimulatorRepositoryClient/
    Client.swift
    TestKey.swift
  PathActionClient/
    Client.swift
    TestKey.swift
  AppSandboxResetClient/
    Client.swift
    TestKey.swift
```

**권장 패턴:**

```swift
import Dependencies
import DependenciesMacros
import Foundation
import SimControlDomain

@DependencyClient
public struct PathActionClient: Sendable {
  public var openInFinder: @Sendable (_ url: URL?, _ label: String) async -> CommandResult
  public var copy: @Sendable (_ value: String?, _ label: String) async -> CommandResult
  public var copyPath: @Sendable (_ url: URL?, _ label: String) async -> CommandResult
}

extension DependencyValues {
  public var pathAction: PathActionClient {
    get { self[PathActionClient.self] }
    set { self[PathActionClient.self] = newValue }
  }
}
```

**TestKey 패턴:**

```swift
import Dependencies
import Foundation
import SimControlDomain

extension PathActionClient: TestDependencyKey {
  public static let testValue = Self()
  public static let previewValue = Self(
    openInFinder: { _, label in previewCommandResult(label: label) },
    copy: { _, label in previewCommandResult(label: label) },
    copyPath: { _, label in previewCommandResult(label: label) }
  )
}

private func previewCommandResult(label: String) -> CommandResult {
  CommandResult(
    id: "preview-\(label)",
    executable: "preview",
    arguments: [label],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0,
    startedAt: Date(timeIntervalSince1970: 0)
  )
}
```

**검증:**

```bash
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 6: Live client target 생성

**파일:**

- 수정: `Packages/SimControlModules/Package.swift`
- 생성 target: `SimControlClientsLive`
- 생성: `Packages/SimControlModules/Sources/SimControlClientsLive/CoreSimulatorClient+Live.swift`
- 생성: `Packages/SimControlModules/Sources/SimControlClientsLive/SimulatorRepositoryClient+Live.swift`
- 생성: `Packages/SimControlModules/Sources/SimControlClientsLive/PathActionClient+Live.swift`
- 생성: `Packages/SimControlModules/Sources/SimControlClientsLive/AppSandboxResetClient+Live.swift`
- 수정: `SimControl/App/AppContainer.swift`

**목표:**

- concrete service instance는 `AppContainer`에서 한 번만 만든다.
- dependency client는 existing service instance를 감싸는 factory로 만든다.

**권장 factory:**

```swift
public extension CoreSimulatorClient {
  static func live(service: CoreSimulatorService) -> Self {
    Self(
      openSimulatorApp: { await service.openSimulatorApp() },
      bootDevice: { await service.bootDevice(id: $0) }
    )
  }
}
```

**검증:**

```bash
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

추가 확인:

```bash
rg "CoreSimulatorService\\(" SimControl Packages/SimControlModules/Sources/SimControlClients Packages/SimControlModules/Sources/*Feature
```

feature/client interface target에서 concrete service 생성이 없어야 한다.

## Task 7: Workflow client 추출

**파일:**

- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/Workflows/InventoryWorkflowClient.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/Workflows/DeviceLifecycleWorkflowClient.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/Workflows/InstalledAppWorkflowClient.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/Workflows/DeveloperToolWorkflowClient.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/Workflows/PathActionWorkflowClient.swift`
- 수정: `SimControl/Features/MainWindow/Features/MainWindowFeature.swift`
- 이동: `MainWindowFeatureTests`의 관련 test

**목표:**

- `MainWindowFeature`는 validation과 response application에 집중한다.
- command sequence는 workflow client가 담당한다.

**우선순위:**

1. `PathActionWorkflowClient`: refresh가 필요 없는 path/copy flow라 위험이 낮다.
2. `InventoryWorkflowClient`: refresh response handling 중복을 정리한다.
3. `DeviceLifecycleWorkflowClient`: create/clone/rename/erase/delete/pair/unpair.
4. `InstalledAppWorkflowClient`: launch/terminate/uninstall/reset/install on another simulator.
5. `DeveloperToolWorkflowClient`: open URL/push/privacy/location/status bar.

**검증:**

```bash
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS' -only-testing:SimControlTests/MainWindowFeatureTests
swift test --package-path Packages/SimControlModules
```

## Task 8: MainWindowFeature target 이동

**파일:**

- 수정: `Packages/SimControlModules/Package.swift`
- 생성 target: `MainWindowFeature`
- 이동: `SimControl/Features/MainWindow/Features/**`
- 이동: `SimControl/Features/MainWindow/Views/**`
- 이동: `SimControl/Features/CreateDevice/**`
- 이동: `SimControlTests/Features/MainWindow/**`
- 수정: `SimControl/App/SimControlApp.swift`
- 수정: `SimControl/App/AppContainer.swift`

**의존성:**

`MainWindowFeature` depends on:

- `SimControlDomain`
- `SimControlClients`
- `MainWindowWorkflows`
- `ComposableArchitecture`

필요 시:

- `SimControlClientsLive`는 feature target이 아니라 app target에서만 사용한다.

**검증:**

```bash
swift test --package-path Packages/SimControlModules --filter MainWindowFeatureTests
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 9: SharedUI, MenuBarFeature, SettingsFeature 이동

**파일:**

- 생성 target: `SimControlSharedUI`
- 이동: `SimControl/SharedUI/**`
- 생성 target: `MenuBarFeature`
- 이동: `SimControl/Features/MenuBar/**`
- 완료: `SettingsFeature`
- 완료: `SimControl/Features/Settings/**` -> `Packages/SimControlModules/Sources/SettingsFeature/`

**의존성:**

`SimControlSharedUI` depends on:

- `SwiftUI`
- optional `SimControlDomain`

`MenuBarFeature` depends on:

- `SimControlDomain`
- `SimControlClients`
- `SimControlSharedUI`
- `ComposableArchitecture`

`SettingsFeature` depends on:

- `SwiftUI`

**검증:**

```bash
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 10: App target 정리

**파일:**

- 수정: `SimControl/App/SimControlApp.swift`
- 수정: `SimControl/App/AppContainer.swift`
- 유지: `SimControl/App/AppDelegate.swift`
- 삭제: `SimControl/App/AppSceneID.swift`
- 유지: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindowSceneID.swift`
- 유지: `SimControl/Assets.xcassets/**`

**목표:**

- app target은 scene과 live wiring만 담당한다.
- feature 구현 파일은 app target에서 제거한다.
- `AppContainer`는 service instance를 한 번 만들고 client factory를 통해 store dependency를 주입한다.

**검증:**

```bash
find SimControl -type f -name '*.swift' | sort
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

`SimControl` app target에 남는 Swift 파일은 `App/` 중심이어야 한다.

## Task 11: Placeholder 타입 정리

**파일:**

- 검토: `SimControl/State/SettingsStore.swift`
- 검토: `SimControl/State/ActionLogStore.swift`
- 검토: `SimControl/State/ActionState.swift`
- 검토: `SimControl/Services/SimulatorFileMonitor.swift`
- 검토: `SimControl/Services/LinkFolderManager.swift`
- 검토: `SimControl/Services/PermissionCoordinator.swift`

**처리 기준:**

- 지금 쓰이지 않으면 삭제한다.
- 다음 milestone에 필요하면 client/interface부터 정의한다.
- settings persistence가 필요하면 `UserSettingsClient`로 구현한다.
- action log가 필요하면 `ActionLogClient`로 구현한다.

**검증:**

```bash
rg "SettingsStore|ActionLogStore|ActionState|SimulatorFileMonitor|LinkFolderManager|PermissionCoordinator" SimControl Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 12: Resource와 localization 소유권 정리

**파일:**

- 검토: `SimControl/Assets.xcassets/**`
- 검토: `SimControl/Features/**`
- 필요 시 생성: `Packages/SimControlModules/Sources/*/Resources/`

**규칙:**

- app icon과 app-level asset은 app target에 둔다.
- feature-owned resource는 feature target resource로 이동한다.
- user-facing string은 해당 feature module에서 localizable resource를 소유하게 한다.

**검증:**

```bash
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS'
```

## Task 13: 선택 작업 - isowords식 preview app 도입

**파일:**

- 선택 생성: `App/Previews/MainWindowPreview/MainWindowPreviewApp.swift`
- 선택 생성: `App/Previews/SettingsPreview/SettingsPreviewApp.swift`
- 선택 생성: `App/Package.swift`

**목표:**

- feature를 독립 app으로 실행해 dependency override를 쉽게 검증한다.
- 초기에는 SwiftUI preview fixture 정리만으로 대체 가능하다.

**보류 기준:**

- package target 이동이 안정되기 전에는 preview app을 만들지 않는다.
- build scheme이 복잡해지면 나중 단계로 미룬다.

## 완료 기준

- `scripts/verify-modularization.sh`가 통과한다.
- `swift test --package-path Packages/SimControlModules`가 통과한다.
- `xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS,arch=arm64,name=My Mac' -parallel-testing-enabled NO`가 통과한다.
- `SimControlDomain`과 `SimControlInfrastructure`가 SwiftUI/TCA를 import하지 않는다.
- concrete service 생성은 app composition root 또는 live target에만 있다.
- `MainWindowFeature.swift`의 workflow-heavy action handling이 workflow client와 child feature로 분산된다.
- app target은 scene, assets, app delegate, dependency wiring 중심으로 축소된다.

## 참고 자료

- 전략 문서: `docs/architecture/isowords-inspired-modularization.md`
- isowords repository: https://github.com/pointfreeco/isowords
- isowords `Package.swift`: https://github.com/pointfreeco/isowords/blob/main/Package.swift
- swift-dependencies dependency 설계 문서: https://github.com/pointfreeco/swift-dependencies/blob/main/Sources/Dependencies/Documentation.docc/Articles/DesigningDependencies.md
