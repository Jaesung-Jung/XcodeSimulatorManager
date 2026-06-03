/// A selected simulator inventory target.
public struct SimulatorInventorySelection: Equatable, Hashable {
  /// The selected simulator device identifier.
  public var deviceID: String?

  /// The selected installed app identifier.
  public var appID: String?

  /// Creates a simulator inventory selection.
  public init(deviceID: String? = nil, appID: String? = nil) {
    self.deviceID = deviceID
    self.appID = appID
  }
}

/// A domain-level summary of a paired phone and watch simulator.
public struct SimulatorInventoryPairSummary: Equatable, Hashable {
  /// The pair identifier.
  public let id: String

  /// The paired phone simulator identifier.
  public let phoneDeviceID: String

  /// The paired phone simulator name.
  public let phoneName: String

  /// The paired phone simulator UDID.
  public let phoneUDID: String

  /// The paired watch simulator identifier.
  public let watchDeviceID: String

  /// The paired watch simulator name.
  public let watchName: String

  /// The paired watch simulator UDID.
  public let watchUDID: String

  /// The current pair state.
  public let state: DevicePair.State

  /// Creates a simulator pair summary.
  public init(
    id: String,
    phoneDeviceID: String,
    phoneName: String,
    phoneUDID: String,
    watchDeviceID: String,
    watchName: String,
    watchUDID: String,
    state: DevicePair.State
  ) {
    self.id = id
    self.phoneDeviceID = phoneDeviceID
    self.phoneName = phoneName
    self.phoneUDID = phoneUDID
    self.watchDeviceID = watchDeviceID
    self.watchName = watchName
    self.watchUDID = watchUDID
    self.state = state
  }
}
