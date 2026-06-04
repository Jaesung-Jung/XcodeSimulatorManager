/// A raw runtime entry decoded from `simctl list -j`.
public struct SimctlRuntime: Decodable, Equatable {
  /// The raw runtime identifier.
  public let identifier: String?

  /// The runtime display name.
  public let name: String?

  /// The runtime version string.
  public let version: String?

  /// The runtime build version string.
  public let buildVersion: String?

  /// The raw platform string.
  public let platform: String?

  /// Whether simctl reports the runtime as available.
  public let isAvailable: Bool?

  /// The runtime root path.
  public let runtimeRoot: String?

  /// Device types supported by this runtime.
  public let supportedDeviceTypes: [SimctlSupportedDeviceType]

  private enum CodingKeys: String, CodingKey {
    case identifier
    case name
    case version
    case buildVersion = "buildversion"
    case platform
    case isAvailable
    case runtimeRoot
    case supportedDeviceTypes
  }

  /// Decodes a simctl runtime, defaulting absent supported device types to an empty array.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    version = try container.decodeIfPresent(String.self, forKey: .version)
    buildVersion = try container.decodeIfPresent(String.self, forKey: .buildVersion)
    platform = try container.decodeIfPresent(String.self, forKey: .platform)
    isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
    runtimeRoot = try container.decodeIfPresent(String.self, forKey: .runtimeRoot)
    supportedDeviceTypes = try container.decodeIfPresent([SimctlSupportedDeviceType].self, forKey: .supportedDeviceTypes) ?? []
  }
}
