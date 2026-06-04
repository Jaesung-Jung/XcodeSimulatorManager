import Foundation

/// Destructive simulator device confirmation variants.
public enum DeviceDestructiveConfirmationKind: Equatable {
  case erase
  case delete

  var title: LocalizedStringResource {
    switch self {
    case .erase:
      .mainWindowEraseTitle
    case .delete:
      .mainWindowDeleteTitle
    }
  }

  var message: LocalizedStringResource {
    switch self {
    case .erase:
      .mainWindowEraseMessage
    case .delete:
      .mainWindowDeleteMessage
    }
  }

  var actionTitle: LocalizedStringResource {
    switch self {
    case .erase:
      .mainWindowEraseAction
    case .delete:
      .mainWindowDeleteAction
    }
  }
}

/// Confirmation payload for destructive simulator device commands.
public struct DeviceDestructiveConfirmationState: Equatable {
  public let deviceID: String
  public let deviceName: String
  public let deviceUDID: String

  /// Creates a confirmation payload for a destructive simulator device command.
  public init(deviceID: String, deviceName: String, deviceUDID: String) {
    self.deviceID = deviceID
    self.deviceName = deviceName
    self.deviceUDID = deviceUDID
  }
}

/// Confirmation payload for unpairing a phone/watch simulator pair.
public struct UnpairDeviceConfirmationState: Equatable {
  public let pairID: String
  public let phoneName: String
  public let phoneUDID: String
  public let watchName: String
  public let watchUDID: String

  /// Creates a confirmation payload for unpairing a simulator pair.
  public init(
    pairID: String,
    phoneName: String,
    phoneUDID: String,
    watchName: String,
    watchUDID: String
  ) {
    self.pairID = pairID
    self.phoneName = phoneName
    self.phoneUDID = phoneUDID
    self.watchName = watchName
    self.watchUDID = watchUDID
  }
}
