public struct SimctlRuntime: Decodable, Equatable {
  public let identifier: String?
  public let name: String?
  public let version: String?
  public let buildVersion: String?
  public let platform: String?
  public let isAvailable: Bool?
  public let runtimeRoot: String?
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    version = try container.decodeIfPresent(String.self, forKey: .version)
    buildVersion = try container.decodeIfPresent(String.self, forKey: .buildVersion)
    platform = try container.decodeIfPresent(String.self, forKey: .platform)
    isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
    runtimeRoot = try container.decodeIfPresent(String.self, forKey: .runtimeRoot)
    supportedDeviceTypes = try container.decodeIfPresent(
      [SimctlSupportedDeviceType].self,
      forKey: .supportedDeviceTypes
    ) ?? []
  }
}
