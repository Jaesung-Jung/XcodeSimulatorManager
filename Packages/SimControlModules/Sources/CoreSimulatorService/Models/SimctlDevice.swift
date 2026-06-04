/// A raw simulator device entry decoded from `simctl list -j`.
public struct SimctlDevice: Decodable, Equatable {
  /// The simulator UDID reported by simctl.
  public let udid: String?

  /// The simulator display name.
  public let name: String?

  /// The raw simulator state string.
  public let state: String?

  /// Whether simctl reports the device as available.
  public let isAvailable: Bool?

  /// The raw device type identifier.
  public let deviceTypeIdentifier: String?

  /// The simulator data directory path.
  public let dataPath: String?

  /// The simulator log directory path.
  public let logPath: String?

  /// The raw last-boot timestamp string.
  public let lastBootedAt: String?

  /// The simulator data directory size in bytes.
  public let dataPathSize: Int64?
}
