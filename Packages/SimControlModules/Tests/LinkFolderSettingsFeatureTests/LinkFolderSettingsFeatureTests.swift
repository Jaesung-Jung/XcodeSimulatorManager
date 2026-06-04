import ComposableArchitecture
import LinkFolderSettingsFeature
import Testing

@Suite("LinkFolderSettingsFeature")
@MainActor
struct LinkFolderSettingsFeatureTests {
  @Test("link folder path 변경 시 상태가 갱신된다")
  func linkFolderPathChangeUpdatesState() async {
    let path = "/tmp/simcontrol-links"
    let store = TestStore(initialState: LinkFolderSettingsFeature.State()) {
      LinkFolderSettingsFeature()
    }

    await store.send(.linkFolderPathChanged(path)) {
      $0.linkFolderPath = path
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: LinkFolderSettingsFeature.State()) {
      LinkFolderSettingsFeature()
    }

    _ = LinkFolderSettingsView(store: store)
  }
}
