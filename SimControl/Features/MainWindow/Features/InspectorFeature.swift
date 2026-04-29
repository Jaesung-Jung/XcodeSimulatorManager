import ComposableArchitecture

@Reducer
struct InspectorFeature {
  @ObservableState
  struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var device: SimulatorDevice?
    var runtime: SimulatorRuntime?
    var deviceType: SimulatorDeviceType?
    var selectedApp: InstalledApp?

    init(
      snapshot: SimulatorSnapshot? = nil,
      device: SimulatorDevice? = nil,
      runtime: SimulatorRuntime? = nil,
      deviceType: SimulatorDeviceType? = nil,
      selectedApp: InstalledApp? = nil
    ) {
      self.snapshot = snapshot
      self.device = device
      self.runtime = runtime
      self.deviceType = deviceType
      self.selectedApp = selectedApp
    }
  }

  enum Action: Equatable {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
