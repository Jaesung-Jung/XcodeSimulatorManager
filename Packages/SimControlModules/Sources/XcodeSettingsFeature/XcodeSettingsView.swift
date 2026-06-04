import ComposableArchitecture
import SimControlLocalization
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
        prompt: Text(.localizable("settings.xcode.developer_directory_prompt"), bundle: .module)
      ) {
        Text(.localizable("settings.xcode.developer_directory"), bundle: .module)
      }
    } header: {
      Text(.localizable("settings.xcode.section"), bundle: .module)
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
