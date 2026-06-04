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

// MARK: - InspectorView.EnvironmentSection Preview

#if DEBUG

#Preview {
  let snapshot = SimulatorSnapshot(
    generatedAt: Date(timeIntervalSince1970: 1_020),
    xcode: XcodeSelection(
      developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
      version: "26.4",
      isValid: true
    ),
    runtimes: [],
    deviceTypes: [],
    devices: [],
    pairs: [],
    installedAppsByDeviceID: [:],
    warnings: [
      SimulatorWarning(
        id: "preview-warning",
        severity: .warning,
        category: .device,
        message: "Preview warning for simulator inventory.",
        relatedID: "PREVIEW-DEVICE-1"
      )
    ]
  )

  VStack(alignment: .leading, spacing: 18) {
    InspectorView.EnvironmentSection(snapshot: snapshot)
    InspectorView.WarningsSection(warnings: snapshot.warnings)
  }
  .padding(20)
  .frame(width: 360)
}

#endif

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
