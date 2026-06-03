import ComposableArchitecture
import SwiftUI

/// Renders link folder settings.
public struct LinkFolderSettingsView: View {
  private let store: StoreOf<LinkFolderSettingsFeature>

  public init(store: StoreOf<LinkFolderSettingsFeature>) {
    self.store = store
  }

  private var linkFolderPath: Binding<String> {
    Binding(
      get: { store.linkFolderPath },
      set: { store.send(.linkFolderPathChanged($0)) }
    )
  }

  public var body: some View {
    Section("Link Folder") {
      TextField(
        "Folder Path",
        text: linkFolderPath,
        prompt: Text("~/Library/Application Support/SimControl/Links")
      )
    }
  }
}
