import ComposableArchitecture

@Reducer
struct InstalledAppsFeature {
  @ObservableState
  struct State: Equatable {
    var apps: [InstalledApp]
    var availability: InstalledAppsAvailability
    var selectedAppID: String?

    init(
      apps: [InstalledApp] = [],
      availability: InstalledAppsAvailability = .notLoaded,
      selectedAppID: String? = nil
    ) {
      self.apps = apps
      self.availability = availability
      self.selectedAppID = selectedAppID
      validateSelection()
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
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectionChanged(let id):
        state.selectedAppID = id
        return .none
      }
    }
  }
}
