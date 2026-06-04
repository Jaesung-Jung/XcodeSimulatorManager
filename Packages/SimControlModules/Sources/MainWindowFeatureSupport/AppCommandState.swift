/// Tracks an app command currently running for a source app and optional target device.
public struct AppCommandState: Equatable {
  public let command: AppCommand
  public let sourceDeviceID: String
  public let appID: String
  public let targetDeviceID: String?

  /// Creates running-command state for an app command.
  public init(
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
