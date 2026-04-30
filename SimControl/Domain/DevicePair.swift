/// A pairing relationship between a phone simulator and a watch simulator.
///
/// Pair records come from CoreSimulator inventory and may refer to missing or
/// unavailable devices. The repository can keep such records visible as
/// recoverable state instead of treating them as refresh failures.
struct DevicePair: Identifiable, Equatable, Hashable {
  /// The known availability state of the pair.
  enum State: String, Equatable, Hashable {
    /// The pair is active and usable.
    case active

    /// The pair exists but is not currently active.
    case inactive

    /// The pair cannot currently be used because one or both devices are unavailable.
    case unavailable

    /// The pair state could not be mapped from source data.
    case unknown
  }

  /// A stable identifier for the pair.
  let id: String

  /// The identifier of the paired phone simulator.
  let phoneDeviceID: String

  /// The identifier of the paired watch simulator.
  let watchDeviceID: String

  /// The current pair state.
  let state: State
}
