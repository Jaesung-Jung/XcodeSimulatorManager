import ComposableArchitecture
import SimControlDomain

@Reducer
struct SidebarFeature {
  @ObservableState
  struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var refreshState: InventoryRefreshState

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
    }
  }

  enum Action: Equatable {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
