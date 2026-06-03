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

assert_no_files_matching() {
  local description="$1"
  local path="$2"
  local pattern="$3"
  local matches

  matches="$(find "$path" -maxdepth 1 -type f -name "$pattern" | sort)"

  if [[ -n "$matches" ]]; then
    echo "$matches" >&2
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

assert_no_match \
  "MainWindowFeature는 workflow client live 조립을 직접 하지 않고 하위 책임 경계에 위임해야 합니다." \
  '(InventoryWorkflowClient|DeviceLifecycleWorkflowClient|InstalledAppWorkflowClient|DeveloperToolWorkflowClient|PathActionWorkflowClient)\.live\(' \
  "$PACKAGE_SOURCES/MainWindowFeature"

assert_no_match \
  "Swift source는 150자를 넘는 줄을 만들지 않습니다." \
  '.{151,}' \
  "$PACKAGE_SOURCES" \
  "$PACKAGE_TESTS" \
  "$ROOT/SimControl" \
  "$ROOT/SimControlTests"

assert_no_app_swift_sources_outside_app

assert_path_present \
  "MainWindow sheet/form UI는 MainWindowSheetsFeature target으로 분리되어야 합니다." \
  "$PACKAGE_SOURCES/MainWindowSheetsFeature"

assert_no_files_matching \
  "DeveloperToolsFeature는 불필요한 파일별 extension으로 나누지 않고 하나의 feature 파일에 둡니다." \
  "$PACKAGE_SOURCES/DeveloperToolsFeature" \
  "DeveloperToolsFeature+*.swift"

assert_no_files_matching \
  "WorkspaceFeature는 불필요한 파일별 extension으로 나누지 않고 하나의 feature 파일에 둡니다." \
  "$PACKAGE_SOURCES/WorkspaceFeature" \
  "WorkspaceFeature+*.swift"

assert_no_files_matching \
  "MainWindowFeature state 조각은 파일별 extension으로 나누지 않고 MainWindowFeature+State.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features" \
  "MainWindowFeature+State[A-Z]*.swift"

assert_no_files_matching \
  "MainWindowFeature developer tool command 조각은 MainWindowFeature+DeveloperTools.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features" \
  "MainWindowFeature+DeveloperTool[A-Z]*.swift"

assert_no_files_matching \
  "MainWindowFeature device lifecycle command 조각은 MainWindowFeature+DeviceLifecycle.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features" \
  "MainWindowFeature+DeviceLifecycle[A-Z]*.swift"

assert_no_files_matching \
  "MainWindowFeature installed app command 조각은 MainWindowFeature+InstalledApps.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features" \
  "MainWindowFeature+InstalledApps[A-Z]*.swift"

assert_path_absent \
  "MainWindowFeature installed app helper는 MainWindowFeature+InstalledApps.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+InstalledAppHelpers.swift"

assert_path_absent \
  "MainWindowFeature generic helper 조각은 별도 파일로 분리하지 않습니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+Helpers.swift"

assert_path_absent \
  "MainWindowFeature의 command response 조각은 MainWindowFeature+CommandResponseRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+AppCommandResponseRouting.swift"

assert_path_absent \
  "MainWindowFeature의 command response 조각은 MainWindowFeature+CommandResponseRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+DeviceCommandResponseRouting.swift"

assert_path_absent \
  "MainWindowFeature의 command response 조각은 MainWindowFeature+CommandResponseRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+PathCommandResponseRouting.swift"

assert_path_absent \
  "MainWindowFeature workspace routing 조각은 MainWindowFeature+WorkspaceRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+WorkspaceDeveloperToolRouting.swift"

assert_path_absent \
  "MainWindowFeature workspace routing 조각은 MainWindowFeature+WorkspaceRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+WorkspaceDeviceRouting.swift"

assert_path_absent \
  "MainWindowFeature workspace routing 조각은 MainWindowFeature+WorkspaceRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+WorkspaceInstalledAppRouting.swift"

assert_path_absent \
  "MainWindowFeature workspace routing 조각은 MainWindowFeature+WorkspaceRouting.swift에 모읍니다." \
  "$PACKAGE_SOURCES/MainWindowFeature/MainWindow/Features/MainWindowFeature+WorkspacePathRouting.swift"

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
