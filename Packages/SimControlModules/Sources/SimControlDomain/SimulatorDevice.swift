import Foundation

/// A simulator device returned by CoreSimulator inventory.
///
/// `SimulatorDevice` describes the simulator itself and the paths that are safe
/// for other layers to display or pass to filesystem services. It does not
/// execute `simctl` commands or inspect the filesystem directly.
public struct SimulatorDevice: Identifiable, Equatable, Hashable {
  /// The boot lifecycle state of a simulator device.
  public enum State: String, Equatable, Hashable {
    /// The simulator is being created.
    case creating

    /// The simulator is shut down.
    case shutdown

    /// The simulator is in the process of booting.
    case booting

    /// The simulator is currently booted.
    case booted

    /// The simulator is in the process of shutting down.
    case shuttingDown

    /// The simulator state could not be mapped from source data.
    case unknown
  }

  /// A stable identifier for this simulator device.
  public let id: String

  /// The CoreSimulator UDID.
  public let udid: String

  /// The user-visible simulator name.
  public let name: String

  /// The identifier of the runtime used by this device.
  public let runtimeID: String

  /// The identifier of the device type used by this device.
  public let deviceTypeID: String

  /// The platform family for the device.
  public let platform: SimulatorPlatform

  /// The current boot lifecycle state.
  public let state: State

  /// Indicates whether CoreSimulator reports the device as available.
  public let isAvailable: Bool

  /// The simulator data directory URL, when known.
  public let dataPath: URL?

  /// The simulator log directory URL, when known.
  public let logPath: URL?

  /// The last boot time, when CoreSimulator provides it.
  public let lastBootedAt: Date?

  /// The calculated data directory size in bytes, when available.
  public let dataPathSize: Int64?

  /// Creates a simulator device inventory value.
  public init(
    id: String,
    udid: String,
    name: String,
    runtimeID: String,
    deviceTypeID: String,
    platform: SimulatorPlatform,
    state: State,
    isAvailable: Bool,
    dataPath: URL?,
    logPath: URL?,
    lastBootedAt: Date?,
    dataPathSize: Int64?
  ) {
    self.id = id
    self.udid = udid
    self.name = name
    self.runtimeID = runtimeID
    self.deviceTypeID = deviceTypeID
    self.platform = platform
    self.state = state
    self.isAvailable = isAvailable
    self.dataPath = dataPath
    self.logPath = logPath
    self.lastBootedAt = lastBootedAt
    self.dataPathSize = dataPathSize
  }
}
