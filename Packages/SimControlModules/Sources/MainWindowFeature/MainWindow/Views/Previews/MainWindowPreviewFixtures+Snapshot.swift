import Foundation
import SimControlDomain

#if DEBUG

extension MainWindowPreviewFixtures {
  static let snapshot = SimulatorSnapshot(
    generatedAt: Date(timeIntervalSince1970: 1_020),
    xcode: XcodeSelection(
      developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
      version: nil,
      isValid: true
    ),
    runtimes: [runtime],
    deviceTypes: [deviceType],
    devices: [device],
    pairs: [],
    installedAppsByDeviceID: [device.id: [app]],
    warnings: [
      SimulatorWarning(
        id: "preview-warning",
        severity: .warning,
        category: .device,
        message: "Preview warning for simulator inventory.",
        relatedID: device.id
      )
    ]
  )

  static var refreshResult: SimulatorRefreshResult {
    SimulatorRefreshResult(
      snapshot: snapshot,
      xcodeCommandResult: CommandResult(
        id: "preview-xcode",
        executable: "xcode-select",
        arguments: ["-p"],
        stdout: "/Applications/Xcode.app/Contents/Developer\n",
        stderr: "",
        exitCode: 0,
        duration: 0.04,
        startedAt: Date(timeIntervalSince1970: 1_000)
      ),
      listCommandResult: commandResults[0],
      diagnostic: nil
    )
  }
}

#endif
