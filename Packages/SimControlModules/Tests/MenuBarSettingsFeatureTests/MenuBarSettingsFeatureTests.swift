import ComposableArchitecture
import MenuBarSettingsFeature
import Testing

@Suite("MenuBarSettingsFeature")
@MainActor
struct MenuBarSettingsFeatureTests {
  @Test("메뉴 막대 표시 설정 변경 시 상태가 갱신된다")
  func showsMenuBarExtraChangeUpdatesState() async {
    let store = TestStore(initialState: MenuBarSettingsFeature.State()) {
      MenuBarSettingsFeature()
    }

    await store.send(.showsMenuBarExtraChanged(false)) {
      $0.showsMenuBarExtra = false
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: MenuBarSettingsFeature.State()) {
      MenuBarSettingsFeature()
    }

    _ = MenuBarSettingsView(store: store)
  }
}
