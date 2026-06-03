// MARK: - DeveloperToolsFeature.State Availability

extension DeveloperToolsFeature.State {
  public var openDeepLinkDisabledReason: String? {
    runnableDeviceDisabledReason
      ?? Self.urlValidationError(deepLinkURLString)
  }

  public var sendPushDisabledReason: String? {
    runnableDeviceDisabledReason
      ?? Self.pushPayloadValidationError(
        pushPayloadJSON,
        bundleID: pushBundleID
      )
  }

  public var applyPrivacyDisabledReason: String? {
    if let runnableDeviceDisabledReason {
      return runnableDeviceDisabledReason
    }

    if let unsupportedReason = privacyService.unsupportedReason {
      return unsupportedReason
    }

    if privacyAction.requiresBundleID && Self.trimmed(privacyBundleID).isEmpty {
      return "Grant and revoke require a bundle identifier."
    }

    return nil
  }

  public var clearLocationDisabledReason: String? {
    runnableDeviceDisabledReason
  }

  public var clearStatusBarOverrideDisabledReason: String? {
    bootedDeviceDisabledReason
  }

  var runnableDeviceDisabledReason: String? {
    if deviceCommandState != nil {
      return "Another simulator command is running."
    }

    if appCommandState != nil {
      return "An app command is running."
    }

    guard let device else {
      return "Select a simulator."
    }

    guard device.isAvailable else {
      return "Selected simulator is unavailable."
    }

    guard device.state == .booted || device.state == .shutdown else {
      return "Selected simulator must be booted or shutdown."
    }

    return nil
  }

  var bootedDeviceDisabledReason: String? {
    if deviceCommandState != nil {
      return "Another simulator command is running."
    }

    if appCommandState != nil {
      return "An app command is running."
    }

    guard let device else {
      return "Select a simulator."
    }

    guard device.isAvailable else {
      return "Selected simulator is unavailable."
    }

    guard device.state == .booted else {
      return "Selected simulator must be booted."
    }

    return nil
  }
}
