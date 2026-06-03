import Foundation

/// A simulator device returned by CoreSimulator inventory.
///
/// `SimulatorDevice` describes the simulator itself and the paths that are safe
/// for other layers to display or pass to filesystem services. It does not
/// execute `simctl` commands or inspect the filesystem directly.
struct SimulatorDevice: Identifiable, Equatable, Hashable {
  /// The boot lifecycle state of a simulator device.
  enum State: String, Equatable, Hashable {
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
  let id: String

  /// The CoreSimulator UDID.
  let udid: String

  /// The user-visible simulator name.
  let name: String

  /// The identifier of the runtime used by this device.
  let runtimeID: String

  /// The identifier of the device type used by this device.
  let deviceTypeID: String

  /// The platform family for the device.
  let platform: SimulatorPlatform

  /// The current boot lifecycle state.
  let state: State

  /// Indicates whether CoreSimulator reports the device as available.
  let isAvailable: Bool

  /// The simulator data directory URL, when known.
  let dataPath: URL?

  /// The simulator log directory URL, when known.
  let logPath: URL?

  /// The last boot time, when CoreSimulator provides it.
  let lastBootedAt: Date?

  /// The calculated data directory size in bytes, when available.
  let dataPathSize: Int64?
}
