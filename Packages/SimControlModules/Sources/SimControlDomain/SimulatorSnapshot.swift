import Foundation

/// An immutable view of the current simulator environment.
///
/// A snapshot is rebuilt from `simctl` and CoreSimulator data during refresh.
/// Stores can render stale snapshots after refresh failures because the snapshot
/// itself is independent from command execution and UI state.
public struct SimulatorSnapshot: Equatable, Hashable {
  /// The time at which the snapshot was generated.
  public let generatedAt: Date

  /// The active Xcode selection used to build this snapshot.
  public let xcode: XcodeSelection

  /// Installed simulator runtimes.
  public let runtimes: [SimulatorRuntime]

  /// Known simulator device types.
  public let deviceTypes: [SimulatorDeviceType]

  /// Known simulator devices.
  public let devices: [SimulatorDevice]

  /// Known watch and phone pair relationships.
  public let pairs: [DevicePair]

  /// Installed apps grouped by simulator device identifier.
  public let installedAppsByDeviceID: [String: [InstalledApp]]

  /// Recoverable warnings encountered while building the snapshot.
  public let warnings: [SimulatorWarning]

  /// Creates a simulator inventory snapshot.
  public init(
    generatedAt: Date,
    xcode: XcodeSelection,
    runtimes: [SimulatorRuntime],
    deviceTypes: [SimulatorDeviceType],
    devices: [SimulatorDevice],
    pairs: [DevicePair],
    installedAppsByDeviceID: [String: [InstalledApp]],
    warnings: [SimulatorWarning]
  ) {
    self.generatedAt = generatedAt
    self.xcode = xcode
    self.runtimes = runtimes
    self.deviceTypes = deviceTypes
    self.devices = devices
    self.pairs = pairs
    self.installedAppsByDeviceID = installedAppsByDeviceID
    self.warnings = warnings
  }
}
