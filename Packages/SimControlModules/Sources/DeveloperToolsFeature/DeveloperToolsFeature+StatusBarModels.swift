// MARK: - DeveloperToolsFeature.StatusBarDataNetwork

extension DeveloperToolsFeature {
  public enum StatusBarDataNetwork: String, CaseIterable, Equatable, Identifiable {
    case hide
    case wifi
    case threeG
    case fourG
    case lte
    case lteA
    case ltePlus
    case fiveG
    case fiveGPlus
    case fiveGUWB
    case fiveGUC

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
      switch self {
      case .hide:
        "Hide"
      case .wifi:
        "Wi-Fi"
      case .threeG:
        "3G"
      case .fourG:
        "4G"
      case .lte:
        "LTE"
      case .lteA:
        "LTE-A"
      case .ltePlus:
        "LTE+"
      case .fiveG:
        "5G"
      case .fiveGPlus:
        "5G+"
      case .fiveGUWB:
        "5G UWB"
      case .fiveGUC:
        "5G UC"
      }
    }

    public var simctlArgument: String {
      switch self {
      case .hide:
        "hide"
      case .wifi:
        "wifi"
      case .threeG:
        "3g"
      case .fourG:
        "4g"
      case .lte:
        "lte"
      case .lteA:
        "lte-a"
      case .ltePlus:
        "lte+"
      case .fiveG:
        "5g"
      case .fiveGPlus:
        "5g+"
      case .fiveGUWB:
        "5g-uwb"
      case .fiveGUC:
        "5g-uc"
      }
    }
  }
}

// MARK: - DeveloperToolsFeature.StatusBarWifiMode

extension DeveloperToolsFeature {
  public enum StatusBarWifiMode: String, CaseIterable, Equatable, Identifiable {
    case searching
    case failed
    case active

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
      switch self {
      case .searching:
        "Searching"
      case .failed:
        "Failed"
      case .active:
        "Active"
      }
    }

    public var simctlArgument: String {
      rawValue
    }
  }
}

// MARK: - DeveloperToolsFeature.StatusBarCellularMode

extension DeveloperToolsFeature {
  public enum StatusBarCellularMode: String, CaseIterable, Equatable, Identifiable {
    case notSupported
    case searching
    case failed
    case active

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
      switch self {
      case .notSupported:
        "Not Supported"
      case .searching:
        "Searching"
      case .failed:
        "Failed"
      case .active:
        "Active"
      }
    }

    public var simctlArgument: String {
      switch self {
      case .notSupported:
        "notSupported"
      case .searching:
        "searching"
      case .failed:
        "failed"
      case .active:
        "active"
      }
    }
  }
}

// MARK: - DeveloperToolsFeature.StatusBarBatteryState

extension DeveloperToolsFeature {
  public enum StatusBarBatteryState: String, CaseIterable, Equatable, Identifiable {
    case charging
    case charged
    case discharging

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
      switch self {
      case .charging:
        "Charging"
      case .charged:
        "Charged"
      case .discharging:
        "Discharging"
      }
    }

    public var simctlArgument: String {
      rawValue
    }
  }
}
