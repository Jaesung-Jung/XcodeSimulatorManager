public struct DeviceCommandState: Equatable {
  public let command: DeviceCommand
  public let deviceID: String?

  public init(command: DeviceCommand, deviceID: String? = nil) {
    self.command = command
    self.deviceID = deviceID
  }
}
