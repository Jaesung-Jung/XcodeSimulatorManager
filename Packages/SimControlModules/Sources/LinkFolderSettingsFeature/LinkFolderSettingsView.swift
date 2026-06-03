import ComposableArchitecture
import SimControlLocalization
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
    Section {
      TextField(
        text: linkFolderPath,
        prompt: Text(.localizable("settings.link_folder.path_prompt"), bundle: .module)
      ) {
        Text(.localizable("settings.link_folder.path"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.link_folder.section"), bundle: .module)
    }
  }
}
