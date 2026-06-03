import ComposableArchitecture

@Reducer
struct InstalledAppsFeature {
  @ObservableState
  struct State: Equatable {
    var apps: [InstalledApp]
    var availability: InstalledAppsAvailability
    var device: SimulatorDevice?
    var selectedAppID: String?
    var appCommandState: AppCommandState?
    var isDeviceCommandRunning: Bool
    var compatibleInstallTargetCount: Int
    var filters: SimulatorFilters
    var allAppsCount: Int

    init(
      apps: [InstalledApp] = [],
      availability: InstalledAppsAvailability = .notLoaded,
      device: SimulatorDevice? = nil,
      selectedAppID: String? = nil,
      appCommandState: AppCommandState? = nil,
      isDeviceCommandRunning: Bool = false,
      compatibleInstallTargetCount: Int = 0,
      filters: SimulatorFilters = SimulatorFilters(),
      allAppsCount: Int? = nil
    ) {
      self.apps = apps
      self.availability = availability
      self.device = device
      self.selectedAppID = selectedAppID
      self.appCommandState = appCommandState
      self.isDeviceCommandRunning = isDeviceCommandRunning
      self.compatibleInstallTargetCount = compatibleInstallTargetCount
      self.filters = filters
      self.allAppsCount = allAppsCount ?? apps.count
      validateSelection()
    }

    var selectedApp: InstalledApp? {
      guard let selectedAppID else {
        return nil
      }

      return apps.first { $0.id == selectedAppID }
    }

    var isActionRunning: Bool {
      appCommandState != nil || isDeviceCommandRunning
    }

    var canLaunchSelectedApp: Bool {
      guard let device,
            selectedApp != nil,
            device.isAvailable,
            !isActionRunning
      else {
        return false
      }

      return device.state == .booted || device.state == .shutdown
    }

    var canTerminateSelectedApp: Bool {
      guard let device,
            selectedApp != nil,
            device.isAvailable,
            !isActionRunning
      else {
        return false
      }

      return device.state == .booted
    }

    var canUninstallSelectedApp: Bool {
      guard let device,
            selectedApp != nil,
            device.isAvailable,
            !isActionRunning
      else {
        return false
      }

      return device.state == .booted || device.state == .shutdown
    }

    var canResetSelectedAppSandbox: Bool {
      selectedApp?.dataContainer != nil && !isActionRunning
    }

    var canInstallSelectedAppOnAnotherSimulator: Bool {
      selectedApp?.appBundlePath != nil
        && compatibleInstallTargetCount > 0
        && !isActionRunning
    }

    var canUseSelectedAppPaths: Bool {
      selectedApp != nil
    }

    mutating func validateSelection() {
      guard availability == .loaded,
            let selectedAppID
      else {
        return
      }

      if !apps.contains(where: { $0.id == selectedAppID }) {
        self.selectedAppID = nil
      }
    }
  }

  enum Action: Equatable {
    case selectionChanged(String?)
    case launchButtonTapped(String)
    case terminateButtonTapped(String)
    case uninstallButtonTapped(String)
    case resetSandboxButtonTapped(String)
    case installOnAnotherSimulatorButtonTapped(String)
    case openBundleContainerButtonTapped(String)
    case copyBundleContainerButtonTapped(String)
    case openDataContainerButtonTapped(String)
    case copyDataContainerButtonTapped(String)
    case copyBundleIDButtonTapped(String)
    case openAppGroupContainerButtonTapped(String, String)
    case copyAppGroupContainerButtonTapped(String, String)
    case pinButtonTapped(String)
    case appSystemFilterChanged(SimulatorFilters.AppSystemFilter)
    case appGroupFilterChanged(SimulatorFilters.PresenceFilter)
    case appDatabaseFilterChanged(SimulatorFilters.PresenceFilter)
    case appSortChanged(SimulatorFilters.AppSort)
    case appSortDirectionChanged(SimulatorFilters.SortDirection)
    case clearAppFiltersButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectionChanged(let id):
        state.selectedAppID = id
        return .none

      case .launchButtonTapped,
           .terminateButtonTapped,
           .uninstallButtonTapped,
           .resetSandboxButtonTapped,
           .installOnAnotherSimulatorButtonTapped,
           .openBundleContainerButtonTapped,
           .copyBundleContainerButtonTapped,
           .openDataContainerButtonTapped,
           .copyDataContainerButtonTapped,
           .copyBundleIDButtonTapped,
           .openAppGroupContainerButtonTapped,
           .copyAppGroupContainerButtonTapped,
           .pinButtonTapped,
           .appSystemFilterChanged,
           .appGroupFilterChanged,
           .appDatabaseFilterChanged,
           .appSortChanged,
           .appSortDirectionChanged,
           .clearAppFiltersButtonTapped:
        return .none
      }
    }
  }
}
