#if DEBUG
import ComposableArchitecture
import SwiftUI

extension Store where State == XcodeSettingsFeature.State, Action == XcodeSettingsFeature.Action {
  @MainActor
  static var xcodeSettingsPreview: StoreOf<XcodeSettingsFeature> {
    Store(
      initialState: XcodeSettingsFeature.State(
        preferredXcodeDeveloperPath: "/Applications/Xcode.app/Contents/Developer"
      )
    ) {
      XcodeSettingsFeature()
    }
  }
}

#Preview("Xcode Settings") {
  Form {
    XcodeSettingsView(store: .xcodeSettingsPreview)
  }
  .formStyle(.grouped)
  .frame(width: 520)
}
#endif
