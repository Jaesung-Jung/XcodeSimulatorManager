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
    Section("Xcode") {
      TextField(
        "Developer Directory",
        text: preferredXcodeDeveloperPath,
        prompt: Text("/Applications/Xcode.app/Contents/Developer")
      )
    }
  }
}
