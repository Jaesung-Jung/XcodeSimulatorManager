public struct AppCommandState: Equatable {
  let command: AppCommand
  let sourceDeviceID: String
  let appID: String
  let targetDeviceID: String?

  init(
    command: AppCommand,
    sourceDeviceID: String,
    appID: String,
    targetDeviceID: String? = nil
  ) {
    self.command = command
    self.sourceDeviceID = sourceDeviceID
    self.appID = appID
    self.targetDeviceID = targetDeviceID
  }
}
