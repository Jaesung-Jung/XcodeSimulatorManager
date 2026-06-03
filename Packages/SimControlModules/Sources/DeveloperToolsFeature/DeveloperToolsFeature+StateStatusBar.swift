// MARK: - DeveloperToolsFeature.State Status Bar

extension DeveloperToolsFeature.State {
  public var setStatusBarOverrideDisabledReason: String? {
    bootedDeviceDisabledReason
      ?? statusBarOverrideValidationError
  }

  public var statusBarOverrideArguments: [String] {
    var arguments: [String] = []
    let time = Self.trimmed(statusBarTime)
    let wifiBars = Self.trimmed(statusBarWifiBars)
    let cellularBars = Self.trimmed(statusBarCellularBars)
    let batteryLevel = Self.trimmed(statusBarBatteryLevel)

    if !time.isEmpty {
      arguments.append(contentsOf: ["--time", time])
    }

    if let statusBarDataNetwork {
      arguments.append(contentsOf: ["--dataNetwork", statusBarDataNetwork.simctlArgument])
    }

    if let statusBarWifiMode {
      arguments.append(contentsOf: ["--wifiMode", statusBarWifiMode.simctlArgument])
    }

    if !wifiBars.isEmpty {
      arguments.append(contentsOf: ["--wifiBars", wifiBars])
    }

    if let statusBarCellularMode {
      arguments.append(contentsOf: ["--cellularMode", statusBarCellularMode.simctlArgument])
    }

    if !cellularBars.isEmpty {
      arguments.append(contentsOf: ["--cellularBars", cellularBars])
    }

    if statusBarOperatorNameIncluded {
      arguments.append(contentsOf: ["--operatorName", Self.trimmed(statusBarOperatorName)])
    }

    if let statusBarBatteryState {
      arguments.append(contentsOf: ["--batteryState", statusBarBatteryState.simctlArgument])
    }

    if !batteryLevel.isEmpty {
      arguments.append(contentsOf: ["--batteryLevel", batteryLevel])
    }

    return arguments
  }

  private var statusBarOverrideValidationError: String? {
    if statusBarOverrideArguments.isEmpty {
      return "Enter at least one status bar override."
    }

    return Self.integerValidationError(
      statusBarWifiBars,
      label: "Wi-Fi bars",
      range: 0...3
    ) ?? Self.integerValidationError(
      statusBarCellularBars,
      label: "Cellular bars",
      range: 0...4
    ) ?? Self.integerValidationError(
      statusBarBatteryLevel,
      label: "Battery level",
      range: 0...100
    )
  }
}
