/// A raw paired-device entry decoded from `simctl list -j`.
public struct SimctlPair: Decodable, Equatable {
  /// The raw pair state string.
  public let state: String?

  /// The phone device member.
  public let phone: SimctlPairedDevice?

  /// The watch device member.
  public let watch: SimctlPairedDevice?
}
