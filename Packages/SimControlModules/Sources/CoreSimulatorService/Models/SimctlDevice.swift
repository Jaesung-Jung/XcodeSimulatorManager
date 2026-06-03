public struct SimctlDevice: Decodable, Equatable {
  public let udid: String?
  public let name: String?
  public let state: String?
  public let isAvailable: Bool?
  public let deviceTypeIdentifier: String?
  public let dataPath: String?
  public let logPath: String?
  public let lastBootedAt: String?
  public let dataPathSize: Int64?
}
