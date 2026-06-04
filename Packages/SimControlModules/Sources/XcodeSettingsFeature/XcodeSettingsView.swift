import ComposableArchitecture
import SwiftUI

/// Renders Xcode path settings.
public struct XcodeSettingsView: View {
  private let store: StoreOf<XcodeSettingsFeature>

  public init(store: StoreOf<XcodeSettingsFeature>) {
    self.store = store
  }

  private var preferredXcodeDeveloperPath: Binding<String> {
    Binding(
      get: { store.preferredXcodeDeveloperPath },
      set: { store.send(.preferredXcodeDeveloperPathChanged($0)) }
    )
  }

  public var body: some View {
    Section {
      TextField(
        text: preferredXcodeDeveloperPath,
        prompt: Text(LocalizedStringResource.settingsXcodeDeveloperDirectoryPrompt)
      ) {
        Text(LocalizedStringResource.settingsXcodeDeveloperDirectory)
      }
    } header: {
      Text(LocalizedStringResource.settingsXcodeSection)
    }
  }
}

// MARK: - XcodeSettingsView Preview

#if DEBUG

#Preview("Xcode Settings") {
  Form {
    XcodeSettingsView(
      store: Store(
        initialState: XcodeSettingsFeature.State(
          preferredXcodeDeveloperPath: "/Applications/Xcode.app/Contents/Developer"
        )
      ) {
        XcodeSettingsFeature()
      }
    )
  }
  .formStyle(.grouped)
  .frame(width: 520)
}

#endif
