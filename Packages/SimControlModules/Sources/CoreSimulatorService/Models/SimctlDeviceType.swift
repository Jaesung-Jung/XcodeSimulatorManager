/// A raw device type entry decoded from `simctl list -j`.
public struct SimctlDeviceType: Decodable, Equatable {
  /// The raw device type identifier.
  public let identifier: String?

  /// The device type display name.
  public let name: String?

  /// The product family reported by simctl.
  public let productFamily: String?

  /// The model identifier reported by simctl.
  public let modelIdentifier: String?
}
