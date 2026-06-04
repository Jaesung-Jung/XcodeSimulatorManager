/// The top-level raw payload decoded from `simctl list -j`.
public struct SimctlListPayload: Decodable, Equatable {
  /// Raw runtime entries.
  public let runtimes: [SimctlRuntime]

  /// Raw device type entries.
  public let deviceTypes: [SimctlDeviceType]

  /// Raw device entries keyed by runtime identifier.
  public let devicesByRuntimeID: [String: [SimctlDevice]]

  /// Raw paired-device entries keyed by pair identifier.
  public let pairsByID: [String: SimctlPair]

  private enum CodingKeys: String, CodingKey {
    case runtimes
    case deviceTypes = "devicetypes"
    case devices
    case pairs
  }

  /// Decodes a simctl list payload, defaulting absent collections to empty values.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    runtimes = try container.decodeIfPresent([SimctlRuntime].self, forKey: .runtimes) ?? []
    deviceTypes = try container.decodeIfPresent([SimctlDeviceType].self, forKey: .deviceTypes) ?? []
    devicesByRuntimeID = try container.decodeIfPresent([String: [SimctlDevice]].self, forKey: .devices) ?? [:]
    pairsByID = try container.decodeIfPresent([String: SimctlPair].self, forKey: .pairs) ?? [:]
  }
}
