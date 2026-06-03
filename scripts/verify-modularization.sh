#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SOURCES="$ROOT/Packages/SimControlModules/Sources"
PACKAGE_TESTS="$ROOT/Packages/SimControlModules/Tests"

assert_no_match() {
  local description="$1"
  local pattern="$2"
  shift 2

  if rg -n "$pattern" "$@"; then
    echo "error: ${description}" >&2
    exit 1
  fi
}

echo "==> 모듈 경계 검사"

assert_no_match \
  "SimControlDomain은 UI, TCA, dependency, 상위 모듈을 import하면 안 됩니다." \
  '^import (SwiftUI|AppKit|ComposableArchitecture|Dependencies|SimControlClients|SimControlInfrastructure|MainWindowWorkflows|MainWindowFeature)\b' \
  "$PACKAGE_SOURCES/SimControlDomain"

assert_no_match \
  "SimControlInfrastructure는 UI feature, TCA, dependency client layer를 import하면 안 됩니다." \
  '^import (SwiftUI|ComposableArchitecture|Dependencies|SimControlClients|SimControlClientsLive|MainWindowWorkflows|MainWindowFeature)\b' \
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
  "MainWindowFeature는 concrete infrastructure나 live client를 직접 import하면 안 됩니다." \
  '^import (SimControlInfrastructure|SimControlClientsLive)\b' \
  "$PACKAGE_SOURCES/MainWindowFeature"

assert_no_match \
  "feature/workflow/client interface layer에서 concrete service를 직접 생성하면 안 됩니다." \
  '(CoreSimulatorService|AppContainerScanner|AppSandboxResetService|PathActionService|SimulatorRepository)\(' \
  "$PACKAGE_SOURCES/SimControlClients" \
  "$PACKAGE_SOURCES/MainWindowWorkflows" \
  "$PACKAGE_SOURCES/MainWindowFeature"

assert_no_match \
  "Swift source는 150자를 넘는 줄을 만들지 않습니다." \
  '.{151,}' \
  "$PACKAGE_SOURCES" \
  "$PACKAGE_TESTS" \
  "$ROOT/SimControl" \
  "$ROOT/SimControlTests"

echo "==> Swift package 테스트"
swift test --package-path "$ROOT/Packages/SimControlModules"

echo "==> Xcode 앱 테스트"
xcodebuild test \
  -project "$ROOT/SimControl.xcodeproj" \
  -scheme SimControl \
  -destination 'platform=macOS,arch=arm64,name=My Mac' \
  -parallel-testing-enabled NO

echo "==> 모듈화 검증 완료"
