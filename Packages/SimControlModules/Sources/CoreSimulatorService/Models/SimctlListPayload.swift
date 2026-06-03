public struct SimctlListPayload: Decodable, Equatable {
  public let runtimes: [SimctlRuntime]
  public let deviceTypes: [SimctlDeviceType]
  public let devicesByRuntimeID: [String: [SimctlDevice]]
  public let pairsByID: [String: SimctlPair]

  private enum CodingKeys: String, CodingKey {
    case runtimes
    case deviceTypes = "devicetypes"
    case devices
    case pairs
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    runtimes = try container.decodeIfPresent([SimctlRuntime].self, forKey: .runtimes) ?? []
    deviceTypes = try container.decodeIfPresent([SimctlDeviceType].self, forKey: .deviceTypes) ?? []
    devicesByRuntimeID = try container.decodeIfPresent([String: [SimctlDevice]].self, forKey: .devices) ?? [:]
    pairsByID = try container.decodeIfPresent([String: SimctlPair].self, forKey: .pairs) ?? [:]
  }
}
