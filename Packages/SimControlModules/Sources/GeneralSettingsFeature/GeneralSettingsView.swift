import ComposableArchitecture
import SwiftUI

/// Renders general app settings.
public struct GeneralSettingsView: View {
  private let store: StoreOf<GeneralSettingsFeature>

  public init(store: StoreOf<GeneralSettingsFeature>) {
    self.store = store
  }

  private var launchesAtLogin: Binding<Bool> {
    Binding(
      get: { store.launchesAtLogin },
      set: { store.send(.launchesAtLoginChanged($0)) }
    )
  }

  public var body: some View {
    Section("General") {
      Toggle("Launch at Login", isOn: launchesAtLogin)
    }
  }
}
