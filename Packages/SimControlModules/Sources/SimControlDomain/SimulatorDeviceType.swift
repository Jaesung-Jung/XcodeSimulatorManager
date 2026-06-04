/// A simulator device type that can be used to create simulator devices.
///
/// Device type metadata comes from `simctl list -j` and is kept independent from
/// runtime compatibility decisions, which are derived later by repository or
/// service mapping code.
public struct SimulatorDeviceType: Identifiable, Equatable, Hashable {
  /// The CoreSimulator device type identifier.
  public let id: String

  /// The user-visible device type name.
  public let name: String

  /// The product family, such as iPhone or Apple Watch, when available.
  public let productFamily: String?

  /// The hardware model identifier, when available.
  public let modelIdentifier: String?

  /// Creates a simulator device type value.
  public init(
    id: String,
    name: String,
    productFamily: String?,
    modelIdentifier: String?
  ) {
    self.id = id
    self.name = name
    self.productFamily = productFamily
    self.modelIdentifier = modelIdentifier
  }
}
