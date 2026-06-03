# isowords 기반 SimControl 모듈화 아키텍처

**작성일:** 2026-06-04
**현 상태:** Swift Package 기반 마이크로 모듈화 적용 완료

## 목적

SimControl의 아키텍처를 `pointfreeco/isowords`의 방향성에 맞춰 재구성한다. 그대로 복제하지는 않고, SimControl의 macOS 앱 규모에 맞게 다음 원칙을 적용한다.

- 앱 타깃은 composition root로 축소한다.
- domain, client interface, live adapter, workflow, feature, concrete service를 컴파일 타임 모듈로 분리한다.
- 큰 feature는 작은 feature target을 조합한다.
- concrete service는 feature/client/workflow 레이어에서 직접 생성하지 않는다.
- 모듈 경계는 `scripts/verify-modularization.sh`로 반복 검증한다.

## 현재 모듈 수

현재 `Packages/SimControlModules`에는 24개 library product가 있다. 이제 단순한 5-7개 레이어 분리가 아니라, feature와 service가 각각 작은 target으로 분리된 마이크로 모듈라이제이션 구조다.

### Domain

- `SimControlDomain`

### Concrete service

- `CommandExecutionService`
- `CoreSimulatorService`
- `AppContainerScanningService`
- `PathActionService`
- `AppSandboxResetService`
- `SimulatorRepositoryService`
- `SimControlInfrastructure`

`SimControlInfrastructure`는 concrete 구현을 직접 많이 소유하는 큰 모듈이 아니라, 앱 composition root가 기존처럼 편하게 import할 수 있도록 service target을 재수출하는 umbrella target이다.

### Dependency client

- `SimControlClients`
- `SimControlClientsLive`

### Workflow

- `MainWindowWorkflows`

### Feature support

- `MainWindowFeatureSupport`
- `MainWindowDisplaySupport`
- `SimControlSharedUI`

### Leaf feature

- `DeviceListFeature`
- `InstalledAppsFeature`
- `DeveloperToolsFeature`
- `DeviceDetailFeature`
- `InspectorFeature`
- `SidebarFeature`
- `WorkspaceFeature`

### Scene feature

- `MainWindowFeature`
- `MenuBarFeature`
- `SettingsFeature`

## 현재 아키텍처 그래프

```mermaid
flowchart TB
  App["SimControl app target\ncomposition root"] --> MainWindowFeature
  App --> MenuBarFeature
  App --> SettingsFeature
  App --> ClientsLive["SimControlClientsLive"]
  App --> Infra["SimControlInfrastructure\numbrella"]

  MainWindowFeature --> Workflows["MainWindowWorkflows"]
  MainWindowFeature --> Clients["SimControlClients"]
  MainWindowFeature --> WorkspaceFeature
  MainWindowFeature --> SidebarFeature
  MainWindowFeature --> LeafFeatures["DeviceList / InstalledApps\nDeveloperTools / DeviceDetail / Inspector"]
  MainWindowFeature --> Support["FeatureSupport / DisplaySupport / SharedUI"]
  MainWindowFeature --> Domain["SimControlDomain"]

  MenuBarFeature --> MainWindowFeature
  MenuBarFeature --> WorkspaceFeature
  MenuBarFeature --> LeafFeatures

  WorkspaceFeature --> LeafFeatures
  SidebarFeature --> Support
  LeafFeatures --> Support
  LeafFeatures --> Domain
  Workflows --> Clients
  Workflows --> Domain

  ClientsLive --> Clients
  ClientsLive --> Infra
  Clients --> Domain

  Infra --> CommandExecutionService
  Infra --> CoreSimulatorService
  Infra --> AppContainerScanningService
  Infra --> AppSandboxResetService
  Infra --> PathActionService
  Infra --> SimulatorRepositoryService

  SimulatorRepositoryService --> CoreSimulatorService
  SimulatorRepositoryService --> AppContainerScanningService
  CoreSimulatorService --> CommandExecutionService
  CommandExecutionService --> Domain
  CoreSimulatorService --> Domain
  AppContainerScanningService --> Domain
  AppSandboxResetService --> Domain
  PathActionService --> Domain
  SimulatorRepositoryService --> Domain
```

## 계층별 책임

### `SimControl` app target

앱 실행과 live object graph 조립만 담당한다.

- `SimControlApp`
- `AppDelegate`
- `AppContainer`
- assets
- scene 선언
- live service instance 생성
- TCA dependency 주입

규칙:

- feature 구현을 두지 않는다.
- old `Domain/`, `Features/`, `Services/`, `Repositories/`, `SharedUI/`, `State/` 폴더를 다시 만들지 않는다.
- concrete service 생성은 `AppContainer` 또는 live adapter에만 둔다.

### `SimControlDomain`

순수 domain model과 inventory query rule을 소유한다.

대표 타입:

- `SimulatorSnapshot`
- `SimulatorDevice`
- `SimulatorRuntime`
- `SimulatorDeviceType`
- `InstalledApp`
- `AppGroupContainer`
- `DevicePair`
- `XcodeSelection`
- `SimulatorWarning`
- `CommandResult`
- `SimulatorFilters`
- `SimulatorInventoryQuery`
- `SimulatorInventorySelection`

규칙:

- `SwiftUI`, `AppKit`, `ComposableArchitecture`, `Dependencies` import 금지.
- process/file I/O 금지.
- UI feature state를 반환하지 않는다.

### Concrete service targets

외부 세계와 직접 통신하는 구현을 작은 target 단위로 나눈다.

- `CommandExecutionService`: process 실행, stdout/stderr 수집, timeout 처리.
- `CoreSimulatorService`: `simctl` 명령 실행과 simctl DTO decode.
- `AppContainerScanningService`: simulator app/container 파일 스캔.
- `PathActionService`: Finder 열기, clipboard 복사 같은 macOS path action.
- `AppSandboxResetService`: 앱 sandbox reset 구현.
- `SimulatorRepositoryService`: core simulator 결과와 app container scan 결과를 domain snapshot으로 조립.
- `SimControlInfrastructure`: 위 service target들을 재수출하는 umbrella.

규칙:

- service target은 feature/client/workflow/infrastructure umbrella를 import하지 않는다.
- 대부분의 service target은 `Foundation`과 `SimControlDomain` 중심으로 유지한다.
- `PathActionService`의 `AppKit` import는 Finder/clipboard 연동을 위한 예외다.
- TCA dependency key를 두지 않는다.

### `SimControlClients`

feature와 workflow가 사용하는 dependency interface를 소유한다.

대표 client:

- `CoreSimulatorClient`
- `SimulatorRepositoryClient`
- `PathActionClient`
- `AppSandboxResetClient`

규칙:

- concrete service를 생성하지 않는다.
- `SimControlInfrastructure`를 import하지 않는다.
- live 구현을 두지 않는다.
- test/preview 기본값은 interface target 안에 둔다.

### `SimControlClientsLive`

dependency client를 concrete service에 연결하는 live adapter를 소유한다.

대표 파일:

- `CoreSimulatorClient+Live.swift`
- `SimulatorRepositoryClient+Live.swift`
- `PathActionClient+Live.swift`
- `AppSandboxResetClient+Live.swift`

규칙:

- `SimControlClients`와 `SimControlInfrastructure`에 의존한다.
- concrete service instance를 받아 client closure로 감싼다.
- feature target은 이 모듈을 import하지 않는다.

### `MainWindowWorkflows`

main window에서 발생하는 command orchestration을 reducer 밖으로 분리한다.

대표 workflow:

- `InventoryWorkflowClient`
- `DeviceLifecycleWorkflowClient`
- `InstalledAppWorkflowClient`
- `DeveloperToolWorkflowClient`
- `PathActionWorkflowClient`

규칙:

- `SimControlClients`와 `SimControlDomain`에만 의존한다.
- live 구현이나 concrete service를 import하지 않는다.
- reducer는 workflow를 호출하고 결과 반영에 집중한다.

### Feature support targets

feature 간 공유되지만 domain은 아닌 타입과 표시 helper를 소유한다.

- `MainWindowFeatureSupport`: command state, command enum, availability enum.
- `MainWindowDisplaySupport`: domain value의 화면 표시 문자열/색상 보조.
- `SimControlSharedUI`: `StatusBadge`, `SectionHeader`, `EmptyStateView`.

규칙:

- shared UI는 특정 feature state를 import하지 않는다.
- support target은 concrete service나 live client를 모른다.

### Leaf feature targets

작은 화면/영역 단위의 TCA reducer와 view를 소유한다.

- `DeviceListFeature`
- `InstalledAppsFeature`
- `DeveloperToolsFeature`
- `DeviceDetailFeature`
- `InspectorFeature`
- `SidebarFeature`
- `WorkspaceFeature`

규칙:

- domain, support, shared UI, TCA에 의존한다.
- concrete service와 live client를 직접 import하지 않는다.
- `WorkspaceFeature`는 leaf feature state를 조합하지만 command execution을 직접 수행하지 않는다.

### Scene feature targets

앱 scene 단위의 feature를 소유한다.

- `MainWindowFeature`: main window reducer, view, sheet/confirmation, workflow 호출.
- `MenuBarFeature`: menu bar extra UI. 현재는 동일한 `StoreOf<MainWindowFeature>`를 보여주는 adapter 역할이므로 `MainWindowFeature`에 의존한다.
- `SettingsFeature`: settings scene SwiftUI view.

`MenuBarFeature -> MainWindowFeature` 의존성은 현재 의도된 타협이다. menu bar가 별도 상태/액션을 가져야 할 만큼 커지면 `MenuBarState`와 `MenuBarAction`을 분리해 이 의존성을 줄인다.

## isowords에서 가져온 원칙

- 앱 타깃은 feature 구현이 아니라 composition root다.
- 큰 feature는 여러 작은 feature target을 조합한다.
- 외부 효과는 dependency client interface와 live implementation으로 분리한다.
- domain model은 feature, UI, live 구현으로부터 독립시킨다.
- resource와 preview fixture는 가능하면 소유 feature target에 둔다.
- 모듈 경계는 문서가 아니라 빌드와 테스트로 강제한다.

## 금지 의존성

`scripts/verify-modularization.sh`에서 다음 규칙을 검사한다.

- `SimControlDomain`은 UI, TCA, dependency, 상위 모듈을 import하지 않는다.
- 순수 service target은 UI/AppKit, TCA, dependency, 상위 모듈을 import하지 않는다.
- service target은 feature/client/workflow/infrastructure umbrella layer를 import하지 않는다.
- `SimControlInfrastructure`는 UI feature, TCA, dependency client layer를 import하지 않는다.
- `SimControlClients`는 live 구현, concrete infrastructure, UI/TCA layer를 import하지 않는다.
- `SimControlClientsLive`는 feature/workflow layer를 import하지 않는다.
- `MainWindowWorkflows`는 live 구현, concrete infrastructure, UI/TCA layer를 import하지 않는다.
- feature target은 `SimControlInfrastructure`, `SimControlClientsLive`를 직접 import하지 않는다.
- feature/workflow/client interface layer에서는 concrete service를 직접 생성하지 않는다.

## 검증 명령

전체 검증:

```bash
scripts/verify-modularization.sh
```

개별 검증:

```bash
swift test --package-path Packages/SimControlModules
xcodebuild test -project SimControl.xcodeproj -scheme SimControl -destination 'platform=macOS,arch=arm64,name=My Mac' -parallel-testing-enabled NO
```

## 남은 선택지

현재 구조는 local package 방식으로 안정화되어 있다. 후속으로 고려할 수 있는 선택지는 다음 정도다.

- `MenuBarFeature`가 독립 상태를 갖게 될 때 `MainWindowFeature` 의존성 제거.
- feature별 preview app 또는 preview harness 추가.
- resource/localization을 feature target 소유로 이동.
- repository layout을 isowords처럼 root `Package.swift` 중심으로 승격할지 결정.

현 단계에서는 root package 승격보다 현재 local package 구조를 유지하는 쪽이 더 비용 대비 효과가 좋다.

## 참고 자료

- `pointfreeco/isowords`: https://github.com/pointfreeco/isowords
- isowords `Package.swift`: https://github.com/pointfreeco/isowords/blob/main/Package.swift
- swift-dependencies dependency 설계 문서: https://github.com/pointfreeco/swift-dependencies/blob/main/Sources/Dependencies/Documentation.docc/Articles/DesigningDependencies.md
