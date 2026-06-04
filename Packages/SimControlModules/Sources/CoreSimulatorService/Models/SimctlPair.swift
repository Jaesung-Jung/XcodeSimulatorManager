public struct SimctlPair: Decodable, Equatable {
  public let state: String?
  public let phone: SimctlPairedDevice?
  public let watch: SimctlPairedDevice?
}
