import ComposableArchitecture
import SwiftUI

/// Renders link folder settings.
public struct LinkFolderSettingsView: View {
  private let store: StoreOf<LinkFolderSettingsFeature>

  /// Creates a link folder settings view bound to a link folder settings store.
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
        prompt: Text(LocalizedStringResource.settingsLinkFolderPathPrompt)
      ) {
        Text(LocalizedStringResource.settingsLinkFolderPath)
      }
    } header: {
      Text(LocalizedStringResource.settingsLinkFolderSection)
    }
  }
}

// MARK: - LinkFolderSettingsView Preview

#if DEBUG

#Preview("Link Folder Settings") {
  Form {
    LinkFolderSettingsView(
      store: Store(
        initialState: LinkFolderSettingsFeature.State(
          linkFolderPath: "~/Library/Application Support/SimControl/Links"
        )
      ) {
        LinkFolderSettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
