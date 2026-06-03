import ComposableArchitecture
import SafetySettingsFeature
import Testing

@Suite("SafetySettingsFeature")
@MainActor
struct SafetySettingsFeatureTests {
  @Test("파괴적 동작 확인 설정 변경 시 상태가 갱신된다")
  func confirmsDestructiveActionsChangeUpdatesState() async {
    let store = TestStore(initialState: SafetySettingsFeature.State()) {
      SafetySettingsFeature()
    }

    await store.send(.confirmsDestructiveActionsChanged(false)) {
      $0.confirmsDestructiveActions = false
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: SafetySettingsFeature.State()) {
      SafetySettingsFeature()
    }

    _ = SafetySettingsView(store: store)
  }
}
