import ComposableArchitecture
import GeneralSettingsFeature
import Testing

@Suite("GeneralSettingsFeature")
@MainActor
struct GeneralSettingsFeatureTests {
  @Test("로그인 시작 설정 변경 시 상태가 갱신된다")
  func launchesAtLoginChangeUpdatesState() async {
    let store = TestStore(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    }

    await store.send(.launchesAtLoginChanged(true)) {
      $0.launchesAtLogin = true
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: GeneralSettingsFeature.State()) {
      GeneralSettingsFeature()
    }

    _ = GeneralSettingsView(store: store)
  }
}
