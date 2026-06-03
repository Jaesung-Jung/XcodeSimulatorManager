import ComposableArchitecture
import SwiftUI

struct XcodeSettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var preferredXcodeDeveloperPath: Binding<String> {
    Binding(
      get: { store.settings.preferredXcodeDeveloperPath },
      set: { store.send(.preferredXcodeDeveloperPathChanged($0)) }
    )
  }

  var body: some View {
    Section("Xcode") {
      TextField(
        "Developer Directory",
        text: preferredXcodeDeveloperPath,
        prompt: Text("/Applications/Xcode.app/Contents/Developer")
      )
    }
  }
}
