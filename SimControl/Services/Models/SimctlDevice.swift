struct SimctlDevice: Decodable, Equatable {
  let udid: String?
  let name: String?
  let state: String?
  let isAvailable: Bool?
  let deviceTypeIdentifier: String?
  let dataPath: String?
  let logPath: String?
  let lastBootedAt: String?
  let dataPathSize: Int64?
}
