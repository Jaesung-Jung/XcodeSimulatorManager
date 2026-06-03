struct SimctlPair: Decodable, Equatable {
  let state: String?
  let phone: SimctlPairedDevice?
  let watch: SimctlPairedDevice?
}
