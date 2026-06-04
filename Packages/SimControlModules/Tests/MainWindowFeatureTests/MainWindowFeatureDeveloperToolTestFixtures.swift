import SimControlDomain

struct MainWindowOpenURLCall: Equatable {
  let deviceID: String
  let urlString: String
}

struct MainWindowPushCall: Equatable {
  let deviceID: String
  let bundleID: String?
  let payloadJSON: String
}

struct MainWindowPrivacyCall: Equatable {
  let deviceID: String
  let action: String
  let service: String
  let bundleID: String?
}

struct MainWindowSetLocationCall: Equatable {
  let deviceID: String
  let coordinate: String
}

struct MainWindowStatusBarOverrideCall: Equatable {
  let deviceID: String
  let arguments: [String]
}

actor MainWindowDeveloperToolCommandRecorder {
  private let openURLResult: CommandResult
  private let pushResult: CommandResult
  private let privacyResult: CommandResult
  private let setLocationResult: CommandResult
  private let clearLocationResult: CommandResult
  private let statusBarResult: CommandResult
  private let clearStatusBarResult: CommandResult
  private var recordedOpenURLCalls: [MainWindowOpenURLCall] = []
  private var recordedPushCalls: [MainWindowPushCall] = []
  private var recordedPrivacyCalls: [MainWindowPrivacyCall] = []
  private var recordedSetLocationCalls: [MainWindowSetLocationCall] = []
  private var recordedClearLocationCalls: [String] = []
  private var recordedStatusBarCalls: [MainWindowStatusBarOverrideCall] = []
  private var recordedClearStatusBarCalls: [String] = []

  init(
    openURLResult: CommandResult,
    pushResult: CommandResult,
    privacyResult: CommandResult,
    setLocationResult: CommandResult,
    clearLocationResult: CommandResult,
    statusBarResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "status-bar",
      arguments: ["simctl", "status_bar", "DEVICE", "override"]
    ),
    clearStatusBarResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "clear-status-bar",
      arguments: ["simctl", "status_bar", "DEVICE", "clear"]
    )
  ) {
    self.openURLResult = openURLResult
    self.pushResult = pushResult
    self.privacyResult = privacyResult
    self.setLocationResult = setLocationResult
    self.clearLocationResult = clearLocationResult
    self.statusBarResult = statusBarResult
    self.clearStatusBarResult = clearStatusBarResult
  }

  func openURL(deviceID: String, urlString: String) -> CommandResult {
    recordedOpenURLCalls.append(
      MainWindowOpenURLCall(deviceID: deviceID, urlString: urlString)
    )
    return openURLResult
  }

  func pushNotification(
    deviceID: String,
    bundleID: String?,
    payloadJSON: String
  ) -> CommandResult {
    recordedPushCalls.append(
      MainWindowPushCall(
        deviceID: deviceID,
        bundleID: bundleID,
        payloadJSON: payloadJSON
      )
    )
    return pushResult
  }

  func setPrivacyPermission(
    deviceID: String,
    action: String,
    service: String,
    bundleID: String?
  ) -> CommandResult {
    recordedPrivacyCalls.append(
      MainWindowPrivacyCall(
        deviceID: deviceID,
        action: action,
        service: service,
        bundleID: bundleID
      )
    )
    return privacyResult
  }

  func setLocation(deviceID: String, coordinate: String) -> CommandResult {
    recordedSetLocationCalls.append(
      MainWindowSetLocationCall(deviceID: deviceID, coordinate: coordinate)
    )
    return setLocationResult
  }

  func clearLocation(deviceID: String) -> CommandResult {
    recordedClearLocationCalls.append(deviceID)
    return clearLocationResult
  }

  func setStatusBarOverride(deviceID: String, arguments: [String]) -> CommandResult {
    recordedStatusBarCalls.append(
      MainWindowStatusBarOverrideCall(deviceID: deviceID, arguments: arguments)
    )
    return statusBarResult
  }

  func clearStatusBarOverride(deviceID: String) -> CommandResult {
    recordedClearStatusBarCalls.append(deviceID)
    return clearStatusBarResult
  }

  func openURLCalls() -> [MainWindowOpenURLCall] {
    recordedOpenURLCalls
  }

  func pushCalls() -> [MainWindowPushCall] {
    recordedPushCalls
  }

  func privacyCalls() -> [MainWindowPrivacyCall] {
    recordedPrivacyCalls
  }

  func setLocationCalls() -> [MainWindowSetLocationCall] {
    recordedSetLocationCalls
  }

  func clearLocationCalls() -> [String] {
    recordedClearLocationCalls
  }

  func statusBarCalls() -> [MainWindowStatusBarOverrideCall] {
    recordedStatusBarCalls
  }

  func clearStatusBarCalls() -> [String] {
    recordedClearStatusBarCalls
  }
}
