import ComposableArchitecture
import DiagnosticsSettingsFeature
import Testing

@Suite("DiagnosticsSettingsFeature")
@MainActor
struct DiagnosticsSettingsFeatureTests {
  @Test("진단 설정 변경 시 상태가 갱신된다")
  func enablesDiagnosticsChangeUpdatesState() async {
    let store = TestStore(initialState: DiagnosticsSettingsFeature.State()) {
      DiagnosticsSettingsFeature()
    }

    await store.send(.enablesDiagnosticsChanged(true)) {
      $0.enablesDiagnostics = true
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: DiagnosticsSettingsFeature.State()) {
      DiagnosticsSettingsFeature()
    }

    _ = DiagnosticsSettingsView(store: store)
  }
}
