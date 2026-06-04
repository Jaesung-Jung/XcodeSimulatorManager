/// A raw supported device type entry decoded inside a simctl runtime.
public struct SimctlSupportedDeviceType: Decodable, Equatable {
  /// The raw supported device type identifier.
  public let identifier: String?

  /// The supported device type display name.
  public let name: String?

  /// The product family reported by simctl.
  public let productFamily: String?
}
