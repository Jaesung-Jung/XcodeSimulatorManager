struct SimctlRuntime: Decodable, Equatable {
  let identifier: String?
  let name: String?
  let version: String?
  let buildVersion: String?
  let platform: String?
  let isAvailable: Bool?
  let supportedDeviceTypes: [SimctlSupportedDeviceType]

  private enum CodingKeys: String, CodingKey {
    case identifier
    case name
    case version
    case buildVersion = "buildversion"
    case platform
    case isAvailable
    case supportedDeviceTypes
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    version = try container.decodeIfPresent(String.self, forKey: .version)
    buildVersion = try container.decodeIfPresent(String.self, forKey: .buildVersion)
    platform = try container.decodeIfPresent(String.self, forKey: .platform)
    isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
    supportedDeviceTypes = try container.decodeIfPresent(
      [SimctlSupportedDeviceType].self,
      forKey: .supportedDeviceTypes
    ) ?? []
  }
}
