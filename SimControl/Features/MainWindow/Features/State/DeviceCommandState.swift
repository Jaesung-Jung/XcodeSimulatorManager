struct DeviceCommandState: Equatable {
  let command: DeviceCommand
  let deviceID: String?

  init(command: DeviceCommand, deviceID: String? = nil) {
    self.command = command
    self.deviceID = deviceID
  }
}
