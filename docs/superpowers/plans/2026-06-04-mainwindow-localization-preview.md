# MainWindow, Localization, Preview 작업 계획

> **에이전트 작업자 필수 안내:** 이 계획을 단계별로 실행할 때는 `superpowers:subagent-driven-development` 또는 `superpowers:executing-plans`를 사용합니다. 진행 관리는 체크박스(`- [ ]`)로 추적합니다.

**목표:** `MainWindowFeature`의 비대한 reducer 파일을 먼저 줄이고, 이후 기능별 문자열을 리소스 기반 localization으로 이동한 다음, 동일한 리소스와 상태를 사용하는 preview harness를 추가합니다.

**아키텍처 방향:** `pointfreeco/isowords`처럼 Swift Package target을 기능 단위로 쪼개되, 지금 단계에서는 동작 변경 없이 기존 target 내부의 책임 분리를 먼저 수행합니다. 그 다음 feature-owned resource와 preview fixture를 붙여서 각 기능 모듈이 상태, 화면, 문자열, preview를 스스로 소유하도록 이동합니다.

**기술 스택:** Swift Package Manager, SwiftUI, TCA, Swift Testing, package resources, `scripts/verify-modularization.sh`.

---

### Task 1: MainWindowFeature 물리적 분해

**대상 파일:**
- 수정: `scripts/verify-modularization.sh`
- 수정: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+Models.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+Inventory.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+DeviceLifecycle.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+InstalledApps.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+DeveloperTools.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+PathActions.swift`
- 생성: `Packages/SimControlModules/Sources/MainWindowFeature/MainWindow/Features/MainWindowFeature+Helpers.swift`

- [x] **Step 1: RED 파일 크기 경계 추가**

`MainWindowFeature.swift`가 1,200줄 이하를 유지하도록 검증 스크립트에 `assert_max_lines` 기준을 추가합니다.

- [x] **Step 2: RED 확인**

실행:

```bash
scripts/verify-modularization.sh
```

확인 결과: 기존 `MainWindowFeature.swift`가 2,298줄이라 1,200줄 제한을 초과해 실패했습니다.

- [x] **Step 3: 중첩 model 타입 이동**

Lifecycle sheet, form, confirmation, candidate, app command context, app container path target 타입을 `MainWindowFeature+Models.swift`로 이동합니다. 중첩 타입은 프로젝트 컨벤션에 맞춰 타입별 `extension MainWindowFeature`와 `// MARK:`로 분리합니다.

- [x] **Step 4: workflow helper 그룹 이동**

Inventory/menu bar helper, device lifecycle command helper, installed app command helper, developer tool command helper, path action helper, shared helper를 책임별 extension 파일로 이동합니다.

- [x] **Step 5: GREEN 확인**

실행:

```bash
swift test --package-path Packages/SimControlModules --filter MainWindowFeatureTests
scripts/verify-modularization.sh
git diff --check
git status --short -- .gitignore
```

기대 결과: 모든 명령이 통과하고 `.gitignore`는 변경되지 않아야 합니다.

### Task 2: feature-owned localization resources

**대상 파일:**
- 수정: `Packages/SimControlModules/Package.swift`
- 생성 또는 수정: `Packages/SimControlModules/Sources/**/Resources/` 아래 feature별 resource 파일
- 수정: 하드코딩된 사용자 노출 문자열을 가진 SwiftUI view 파일
- 수정: `scripts/verify-modularization.sh`

- [x] **Step 1: feature target별 하드코딩 문자열 인벤토리 작성**

SwiftUI view 파일에서 `Text("...")`, `Section("...")`, `Toggle("...")`, `Button("...")`, `Label("...", systemImage:)`, `TextField("...")` 호출부를 검색해 feature target별로 분류합니다.

- [x] **Step 2: resource 기반 localization 패턴 확정**

저장소에 기존 localization 패턴이 있으면 재사용합니다. 없다면 Swift Package resource에서 feature module의 bundle을 통해 문자열을 읽는 최소 helper를 도입합니다.

- [x] **Step 3: Settings child feature부터 적용**

최근 분리된 Settings child feature의 문자열을 feature-owned resource로 이동하고 해당 package test를 실행합니다.

- [x] **Step 4: MainWindowFeature 주요 view로 확장**

Preview나 test에서 자주 다루는 MainWindowFeature view의 사용자 노출 문자열을 resource 기반 문자열로 교체합니다.

- [x] **Step 5: localization 검증**

실행:

```bash
swift test --package-path Packages/SimControlModules
scripts/verify-modularization.sh
git diff --check
```

확인 결과: Settings/MainWindow 관련 package test 94개가 통과했고, `scripts/verify-modularization.sh`가 package test와 Xcode test까지 통과했습니다.

### Task 3: preview harness

**대상 파일:**
- 수정 또는 생성: `Packages/SimControlModules/Sources/*Feature/**/Previews/` 아래 preview fixture 파일
- 필요한 경우 수정: package resource fixture

- [ ] **Step 1: 기존 preview와 fixture 점검**

현재 `#Preview` 블록과 preview fixture 파일을 목록화합니다.

- [ ] **Step 2: Settings child feature preview 추가**

각 Settings child feature가 대표 상태로 초기화된 store를 사용해 렌더링되도록 focused preview를 추가합니다.

- [ ] **Step 3: MainWindowFeature preview harness 추가 또는 강화**

Preview 코드는 feature-owned preview 파일에 두고, live dependency를 사용하지 않는 fixture 기반 store를 구성합니다.

- [ ] **Step 4: preview 컴파일 검증**

Package test와 Xcode build/test를 `scripts/verify-modularization.sh`로 실행해 preview 관련 코드가 컴파일되는지 확인합니다.
