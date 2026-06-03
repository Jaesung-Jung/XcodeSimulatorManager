import ComposableArchitecture
import SwiftUI

struct LinkFolderSettingsView: View {
  let store: StoreOf<SettingsFeature>

  private var linkFolderPath: Binding<String> {
    Binding(
      get: { store.settings.linkFolderPath },
      set: { store.send(.linkFolderPathChanged($0)) }
    )
  }

  var body: some View {
    Section("Link Folder") {
      TextField(
        "Folder Path",
        text: linkFolderPath,
        prompt: Text("~/Library/Application Support/SimControl/Links")
      )
    }
  }
}
