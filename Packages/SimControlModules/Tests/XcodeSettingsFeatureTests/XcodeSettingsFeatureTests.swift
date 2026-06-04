import ComposableArchitecture
import Testing
import XcodeSettingsFeature

@Suite("XcodeSettingsFeature")
@MainActor
struct XcodeSettingsFeatureTests {
  @Test("Xcode developer path 변경 시 상태가 갱신된다")
  func preferredXcodeDeveloperPathChangeUpdatesState() async {
    let path = "/Applications/Xcode-beta.app/Contents/Developer"
    let store = TestStore(initialState: XcodeSettingsFeature.State()) {
      XcodeSettingsFeature()
    }

    await store.send(.preferredXcodeDeveloperPathChanged(path)) {
      $0.preferredXcodeDeveloperPath = path
    }
  }

  @Test("루트 모듈 밖에서 view를 생성할 수 있다")
  func viewCanBeConstructedFromOutsideTheModule() {
    let store = Store(initialState: XcodeSettingsFeature.State()) {
      XcodeSettingsFeature()
    }

    _ = XcodeSettingsView(store: store)
  }
}
