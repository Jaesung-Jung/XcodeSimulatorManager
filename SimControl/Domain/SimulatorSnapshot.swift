import Foundation

/// An immutable view of the current simulator environment.
///
/// A snapshot is rebuilt from `simctl` and CoreSimulator data during refresh.
/// Stores can render stale snapshots after refresh failures because the snapshot
/// itself is independent from command execution and UI state.
struct SimulatorSnapshot: Equatable, Hashable {
  /// The time at which the snapshot was generated.
  let generatedAt: Date

  /// The active Xcode selection used to build this snapshot.
  let xcode: XcodeSelection

  /// Installed simulator runtimes.
  let runtimes: [SimulatorRuntime]

  /// Known simulator device types.
  let deviceTypes: [SimulatorDeviceType]

  /// Known simulator devices.
  let devices: [SimulatorDevice]

  /// Known watch and phone pair relationships.
  let pairs: [DevicePair]

  /// Installed apps grouped by simulator device identifier.
  let installedAppsByDeviceID: [String: [InstalledApp]]

  /// Recoverable warnings encountered while building the snapshot.
  let warnings: [SimulatorWarning]
}
