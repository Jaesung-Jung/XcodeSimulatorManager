/// A pairing relationship between a phone simulator and a watch simulator.
///
/// Pair records come from CoreSimulator inventory and may refer to missing or
/// unavailable devices. The repository can keep such records visible as
/// recoverable state instead of treating them as refresh failures.
public struct DevicePair: Identifiable, Equatable, Hashable {
  /// The known availability state of the pair.
  public enum State: String, Equatable, Hashable {
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
  public let id: String

  /// The identifier of the paired phone simulator.
  public let phoneDeviceID: String

  /// The identifier of the paired watch simulator.
  public let watchDeviceID: String

  /// The current pair state.
  public let state: State

  /// Creates a simulator device pair value.
  public init(
    id: String,
    phoneDeviceID: String,
    watchDeviceID: String,
    state: State
  ) {
    self.id = id
    self.phoneDeviceID = phoneDeviceID
    self.watchDeviceID = watchDeviceID
    self.state = state
  }
}
