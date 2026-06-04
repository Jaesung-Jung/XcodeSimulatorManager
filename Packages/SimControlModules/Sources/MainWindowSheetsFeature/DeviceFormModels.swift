import SimControlDomain

/// Form state used to create a simulator device.
public struct CreateDeviceFormState: Equatable {
  public var name: String
  public var runtimeID: String
  public var deviceTypeID: String

  /// Creates form state for a create-device sheet.
  public init(
    name: String = "",
    runtimeID: String = "",
    deviceTypeID: String = ""
  ) {
    self.name = name
    self.runtimeID = runtimeID
    self.deviceTypeID = deviceTypeID
  }
}

/// Form state used to clone a simulator device.
public struct CloneDeviceFormState: Equatable {
  public let sourceDeviceID: String
  public let sourceName: String
  public var name: String

  /// Creates form state for a clone-device sheet.
  public init(sourceDeviceID: String, sourceName: String, name: String) {
    self.sourceDeviceID = sourceDeviceID
    self.sourceName = sourceName
    self.name = name
  }
}

/// Form state used to rename a simulator device.
public struct RenameDeviceFormState: Equatable {
  public let deviceID: String
  public let currentName: String
  public var name: String

  /// Creates form state for a rename-device sheet.
  public init(deviceID: String, currentName: String, name: String) {
    self.deviceID = deviceID
    self.currentName = currentName
    self.name = name
  }
}

/// Candidate simulator device that can participate in a phone/watch pair.
public struct PairDeviceCandidate: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let udid: String

  /// Creates a pairing candidate from a simulator device.
  public init(device: SimulatorDevice) {
    self.id = device.id
    self.name = device.name
    self.udid = device.udid
  }
}

/// Form state used to pair a phone simulator with a watch simulator.
public struct PairDevicesFormState: Equatable {
  public var phoneDeviceID: String
  public var watchDeviceID: String

  /// Creates form state for a pair-devices sheet.
  public init(phoneDeviceID: String, watchDeviceID: String) {
    self.phoneDeviceID = phoneDeviceID
    self.watchDeviceID = watchDeviceID
  }
}
