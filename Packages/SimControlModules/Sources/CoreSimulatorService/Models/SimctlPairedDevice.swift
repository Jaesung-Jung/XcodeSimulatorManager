/// A raw device member inside a simctl pair entry.
public struct SimctlPairedDevice: Decodable, Equatable {
  /// The paired device UDID.
  public let udid: String?

  /// The paired device display name.
  public let name: String?

  /// The raw paired device state string.
  public let state: String?
}
