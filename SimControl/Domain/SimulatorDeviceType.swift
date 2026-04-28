/// A simulator device type that can be used to create simulator devices.
///
/// Device type metadata comes from `simctl list -j` and is kept independent from
/// runtime compatibility decisions, which are derived later by repository or
/// service mapping code.
struct SimulatorDeviceType: Identifiable, Equatable, Hashable {
  /// The CoreSimulator device type identifier.
  let id: String

  /// The user-visible device type name.
  let name: String

  /// The product family, such as iPhone or Apple Watch, when available.
  let productFamily: String?

  /// The hardware model identifier, when available.
  let modelIdentifier: String?
}
