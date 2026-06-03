#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SOURCES="$ROOT/Packages/SimControlModules/Sources"
PACKAGE_TESTS="$ROOT/Packages/SimControlModules/Tests"

SERVICE_SOURCES=(
  "$PACKAGE_SOURCES/CommandExecutionService"
  "$PACKAGE_SOURCES/CoreSimulatorService"
  "$PACKAGE_SOURCES/AppContainerScanningService"
  "$PACKAGE_SOURCES/AppSandboxResetService"
  "$PACKAGE_SOURCES/PathActionService"
  "$PACKAGE_SOURCES/SimulatorRepositoryService"
)

PURE_SERVICE_SOURCES=(
  "$PACKAGE_SOURCES/CommandExecutionService"
  "$PACKAGE_SOURCES/CoreSimulatorService"
  "$PACKAGE_SOURCES/AppContainerScanningService"
  "$PACKAGE_SOURCES/AppSandboxResetService"
  "$PACKAGE_SOURCES/SimulatorRepositoryService"
)

FEATURE_SOURCES=(
  "$PACKAGE_SOURCES/DeviceListFeature"
  "$PACKAGE_SOURCES/InstalledAppsFeature"
  "$PACKAGE_SOURCES/DeveloperToolsFeature"
  "$PACKAGE_SOURCES/DeviceDetailFeature"
  "$PACKAGE_SOURCES/InspectorFeature"
  "$PACKAGE_SOURCES/SidebarFeature"
  "$PACKAGE_SOURCES/WorkspaceFeature"
  "$PACKAGE_SOURCES/MenuBarFeature"
  "$PACKAGE_SOURCES/MainWindowSheetsFeature"
  "$PACKAGE_SOURCES/MainWindowFeature"
  "$PACKAGE_SOURCES/GeneralSettingsFeature"
  "$PACKAGE_SOURCES/MenuBarSettingsFeature"
  "$PACKAGE_SOURCES/SafetySettingsFeature"
  "$PACKAGE_SOURCES/XcodeSettingsFeature"
  "$PACKAGE_SOURCES/LinkFolderSettingsFeature"
  "$PACKAGE_SOURCES/DiagnosticsSettingsFeature"
  "$PACKAGE_SOURCES/SettingsFeature"
)

SETTINGS_CHILD_FEATURE_SOURCES=(
  "$PACKAGE_SOURCES/GeneralSettingsFeature"
  "$PACKAGE_SOURCES/MenuBarSettingsFeature"
  "$PACKAGE_SOURCES/SafetySettingsFeature"
  "$PACKAGE_SOURCES/XcodeSettingsFeature"
  "$PACKAGE_SOURCES/LinkFolderSettingsFeature"
  "$PACKAGE_SOURCES/DiagnosticsSettingsFeature"
)

assert_no_match() {
  local description="$1"
  local pattern="$2"
  shift 2

  if rg -n "$pattern" "$@"; then
    echo "error: ${description}" >&2
    exit 1
  fi
}

assert_no_app_swift_sources_outside_app() {
  local unexpected
  unexpected="$(find "$ROOT/SimControl" -type f -name '*.swift' ! -path "$ROOT/SimControl/App/*" | sort)"

  if [[ -n "$unexpected" ]]; then
    echo "$unexpected" >&2
    echo "error: SimControl app target에는 App/ 밖의 Swift source를 남기지 않습니다." >&2
    exit 1
  fi
}

assert_path_absent() {
  local description="$1"
  local path="$2"

  if [[ -e "$path" ]]; then
    find "$path" -maxdepth 3 -print | sort >&2
    echo "error: ${description}" >&2
    exit 1
  fi
}

assert_path_present() {
  local description="$1"
  local path="$2"

  if [[ ! -e "$path" ]]; then
    echo "$path" >&2
    echo "error: ${description}" >&2
    exit 1
  fi
}

assert_max_lines() {
  local description="$1"
  local max_lines="$2"
  local path="$3"
  local line_count

  line_count="$(wc -l < "$path" | tr -d ' ')"

  if (( line_count > max_lines )); then
    echo "$path has $line_count lines; limit is $max_lines." >&2
    echo "error: ${description}" >&2
    exit 1
  fi
}

echo "==> 모듈 경계 검사"

assert_no_match \
  "SimControlDomain은 UI, TCA, dependency, 상위 모듈을 import하면 안 됩니다." \
  '^import (SwiftUI|AppKit|ComposableArchitecture|Dependencies|SimControlClients|SimControlInfrastructure|MainWindowWorkflows|.*Feature)\b' \
  "$PACKAGE_SOURCES/SimControlDomain"

assert_no_match \
  "순수 service target은 UI/AppKit, TCA, dependency layer를 import하면 안 됩니다." \
  '^import (SwiftUI|AppKit|ComposableArchitecture|Dependencies)\b' \
  "${PURE_SERVICE_SOURCES[@]}"

assert_no_match \
  "순수 service target은 client/live/workflow/infrastructure/feature layer를 import하면 안 됩니다." \
  '^import (SimControlClients|SimControlClientsLive|MainWindowWorkflows|SimControlInfrastructure|.*Feature)\b' \
  "${PURE_SERVICE_SOURCES[@]}"

assert_no_match \
  "service target은 UI/TCA/dependency layer를 import하면 안 됩니다." \
  '^import (SwiftUI|ComposableArchitecture|Dependencies)\b' \
  "${SERVICE_SOURCES[@]}"

assert_no_match \
  "service target은 feature/client/workflow/infrastructure umbrella layer를 import하면 안 됩니다." \
  '^import (SimControlClients|SimControlClientsLive|MainWindowWorkflows|SimControlInfrastructure|.*Feature)\b' \
  "${SERVICE_SOURCES[@]}"

assert_no_match \
  "SimControlInfrastructure는 UI feature, TCA, dependency client layer를 import하면 안 됩니다." \
  '^import (SwiftUI|ComposableArchitecture|Dependencies|SimControlClients|SimControlClientsLive|MainWindowWorkflows|.*Feature)\b' \
  "$PACKAGE_SOURCES/SimControlInfrastructure"

assert_no_match \
  "SimControlClients는 live 구현, concrete infrastructure, UI/TCA layer를 import하면 안 됩니다." \
  '^import (SwiftUI|AppKit|ComposableArchitecture|SimControlInfrastructure|SimControlClientsLive|MainWindowWorkflows|MainWindowFeature)\b' \
  "$PACKAGE_SOURCES/SimControlClients"

assert_no_match \
  "SimControlClientsLive는 feature/workflow layer를 import하면 안 됩니다." \
  '^import (SwiftUI|ComposableArchitecture|MainWindowWorkflows|MainWindowFeature)\b' \
  "$PACKAGE_SOURCES/SimControlClientsLive"

assert_no_match \
  "MainWindowWorkflows는 live 구현, concrete infrastructure, UI/TCA layer를 import하면 안 됩니다." \
  '^import (SwiftUI|AppKit|ComposableArchitecture|SimControlInfrastructure|SimControlClientsLive|MainWindowFeature)\b' \
  "$PACKAGE_SOURCES/MainWindowWorkflows"

assert_no_match \
  "feature target은 concrete infrastructure나 live client를 직접 import하면 안 됩니다." \
  '^import (SimControlInfrastructure|SimControlClientsLive)\b' \
  "${FEATURE_SOURCES[@]}"

assert_no_match \
  "SettingsFeature는 app/main/menu feature나 live/infrastructure layer를 import하면 안 됩니다." \
  '^import (SimControlInfrastructure|SimControlClientsLive|MainWindowFeature|MenuBarFeature)\b' \
  "$PACKAGE_SOURCES/SettingsFeature"

assert_no_match \
  "Settings child feature는 root scene, sibling settings, client, live, infrastructure layer를 import하면 안 됩니다." \
  '^import (SimControlClients|SimControlClientsLive|SimControlInfrastructure|MainWindowFeature|MenuBarFeature|SettingsFeature|.*SettingsFeature)\b' \
  "${SETTINGS_CHILD_FEATURE_SOURCES[@]}"

assert_no_match \
  "Settings child feature의 사용자 노출 문자열은 .localizable(...)과 feature-owned resource를 사용해야 합니다." \
  '(^|[^A-Za-z])(Text|Section|Toggle|Button|Label|TextField|Picker)\("[^"]+' \
  "${SETTINGS_CHILD_FEATURE_SOURCES[@]}"

assert_no_match \
  "MenuBarFeature는 MainWindowFeature를 직접 import하면 안 됩니다." \
  '^import MainWindowFeature\b' \
  "$PACKAGE_SOURCES/MenuBarFeature"

assert_no_match \
  "MainWindowSheetsFeature는 MainWindowFeature를 직접 import하면 안 됩니다." \
  '^import MainWindowFeature\b' \
  "$PACKAGE_SOURCES/MainWindowSheetsFeature"

assert_no_match \
  "feature/workflow/client interface layer에서 concrete service를 직접 생성하면 안 됩니다." \
  '(CommandExecutor|CoreSimulatorService|AppContainerScanner|AppSandboxResetService|PathActionService|SimulatorRepository)\(' \
  "$PACKAGE_SOURCES/SimControlClients" \
  "$PACKAGE_SOURCES/MainWindowWorkflows" \
  "${FEATURE_SOURCES[@]}"

assert_max_lines \
  "AppContainerScanner.swift는 public entry와 scan orchestration만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/AppContainerScanningService/AppContainerScanner.swift"

assert_max_lines \
  "CoreSimulatorService.swift는 public contract와 dependency wiring만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/CoreSimulatorService/CoreSimulatorService.swift"

assert_max_lines \
  "SimulatorInventoryQuery.swift는 query facade와 저장 상태만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/SimControlDomain/SimulatorInventoryQuery.swift"

assert_max_lines \
  "SimulatorRepository.swift는 actor contract와 refresh entry만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/SimulatorRepositoryService/SimulatorRepository.swift"

assert_max_lines \
  "CommandExecutor.swift는 public contract와 execute orchestration만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/CommandExecutionService/CommandExecutor.swift"

assert_no_match \
  "Swift source는 150자를 넘는 줄을 만들지 않습니다." \
  '.{151,}' \
  "$PACKAGE_SOURCES" \
  "$PACKAGE_TESTS" \
  "$ROOT/SimControl" \
  "$ROOT/SimControlTests"

assert_max_lines \
  "MainWindowFeature.swift는 root action 선언과 reducer 조합만 남겨 250줄 이하로 유지합니다." \
  250 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature.swift"

assert_max_lines \
  "MainWindowFeature+Reducer.swift는 route dispatcher만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+Reducer.swift"

assert_max_lines \
  "MainWindowFeature+DeviceLifecycle.swift는 기본 lifecycle command만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+DeviceLifecycle.swift"

assert_max_lines \
  "MainWindowFeature+InstalledApps.swift는 기본 app command만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+InstalledApps.swift"

assert_max_lines \
  "MainWindowFeature+State.swift는 상태 저장/초기화만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+State.swift"

assert_max_lines \
  "MainWindowFeature+Helpers.swift는 공통 helper만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+Helpers.swift"

assert_max_lines \
  "MainWindowFeature+DeveloperTools.swift는 도구별 command entry만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+DeveloperTools.swift"

assert_max_lines \
  "MainWindowPreviewFixtures.swift는 preview store wiring만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Views/Previews/MainWindowPreviewFixtures.swift"

assert_max_lines \
  "MainWindowView.swift는 root split view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Views/MainWindowView.swift"

assert_max_lines \
  "MainWindowDisplayValues.swift는 platform/device/state display projection만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowDisplaySupport/MainWindowDisplayValues.swift"

assert_max_lines \
  "InstalledAppWorkflowClient.swift는 public model/endpoint contract와 live assembly만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowWorkflows/InstalledAppWorkflowClient.swift"

assert_max_lines \
  "DeveloperToolWorkflowClient.swift는 public endpoint contract와 live assembly만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowWorkflows/DeveloperToolWorkflowClient.swift"

assert_max_lines \
  "DeveloperToolsFeature.swift는 Action과 reducer 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/DeveloperToolsFeature/DeveloperToolsFeature.swift"

assert_max_lines \
  "DeveloperToolsFeature+State.swift는 저장 상태와 초기화만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/DeveloperToolsFeature/DeveloperToolsFeature+State.swift"

assert_max_lines \
  "DeveloperToolsView.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/DeveloperToolsFeature/DeveloperToolsView.swift"

assert_max_lines \
  "InstalledAppsView.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/InstalledAppsFeature/InstalledAppsView.swift"

assert_max_lines \
  "DeviceDetailView.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/DeviceDetailFeature/DeviceDetailView.swift"

assert_max_lines \
  "DeviceListView.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/DeviceListFeature/DeviceListView.swift"

assert_max_lines \
  "MainWindowSheetModels.swift는 sheet enum routing만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/MainWindowSheetsFeature/MainWindowSheetModels.swift"

assert_max_lines \
  "InspectorView.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/InspectorFeature/InspectorView.swift"

assert_max_lines \
  "Sidebar.swift는 root view 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/SidebarFeature/Sidebar.swift"

assert_max_lines \
  "WorkspaceFeature.swift는 feature entry와 reducer 조합만 남겨 180줄 이하로 유지합니다." \
  180 \
  "$PACKAGE_SOURCES/WorkspaceFeature/WorkspaceFeature.swift"

assert_no_app_swift_sources_outside_app

assert_path_present \
  "MainWindow sheet/form UI는 MainWindowSheetsFeature target으로 분리되어야 합니다." \
  "$PACKAGE_SOURCES/MainWindowSheetsFeature"

assert_path_absent \
  "MainWindowFeature에는 sheet/form view 전용 CreateDevice 디렉터리를 남기지 않습니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/CreateDevice"

assert_path_absent "app target에는 예전 Domain 디렉터리를 남기지 않습니다." "$ROOT/SimControl/Domain"
assert_path_absent "app target에는 예전 Features 디렉터리를 남기지 않습니다." "$ROOT/SimControl/Features"
assert_path_absent "app target에는 예전 Repositories 디렉터리를 남기지 않습니다." "$ROOT/SimControl/Repositories"
assert_path_absent "app target에는 예전 Services 디렉터리를 남기지 않습니다." "$ROOT/SimControl/Services"
assert_path_absent "app target에는 예전 SharedUI 디렉터리를 남기지 않습니다." "$ROOT/SimControl/SharedUI"
assert_path_absent "app target에는 예전 State 디렉터리를 남기지 않습니다." "$ROOT/SimControl/State"

echo "==> Swift package 테스트"
swift test --package-path "$ROOT/Packages/SimControlModules"

echo "==> Xcode 앱 테스트"
xcodebuild test \
  -project "$ROOT/SimControl.xcodeproj" \
  -scheme SimControl \
  -destination 'platform=macOS,arch=arm64,name=My Mac' \
  -parallel-testing-enabled NO

echo "==> 모듈화 검증 완료"
