#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == LinkFolderSettingsFeature.State, Action == LinkFolderSettingsFeature.Action {
  @MainActor
  static var linkFolderSettingsPreview: StoreOf<LinkFolderSettingsFeature> {
    Store(
      initialState: LinkFolderSettingsFeature.State(
        linkFolderPath: "~/Library/Application Support/SimControl/Links"
      )
    ) {
      LinkFolderSettingsFeature()
    }
  }
}

#Preview("Link Folder Settings") {
  Form {
    LinkFolderSettingsView(store: .linkFolderSettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
