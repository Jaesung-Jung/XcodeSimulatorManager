import SimControlDomain
import SwiftUI

// MARK: - InspectorView.EnvironmentSection

extension InspectorView {
  struct EnvironmentSection: View {
    let snapshot: SimulatorSnapshot?

    var body: some View {
      InspectorSection("Environment") {
        FieldRow(
          title: "Xcode Path",
          value: snapshot?.xcode.developerPath?.path
        )
        FieldRow(title: "Xcode Version", value: snapshot?.xcode.version)
        FieldRow(
          title: "Last Refresh",
          value: snapshot?.generatedAt.formatted(date: .abbreviated, time: .shortened)
        )
      }
    }
  }
}

// MARK: - InspectorView.WarningsSection

extension InspectorView {
  struct WarningsSection: View {
    let warnings: [SimulatorWarning]

    var body: some View {
      InspectorSection("Warnings") {
        ForEach(warnings) { warning in
          WarningRow(warning: warning)
        }
      }
    }
  }
}
