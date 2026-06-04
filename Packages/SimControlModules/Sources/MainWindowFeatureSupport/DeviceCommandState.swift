/// Tracks a device command currently running for an optional simulator device.
public struct DeviceCommandState: Equatable {
  public let command: DeviceCommand
  public let deviceID: String?

  /// Creates running-command state for a device command.
  public init(command: DeviceCommand, deviceID: String? = nil) {
    self.command = command
    self.deviceID = deviceID
  }
}
