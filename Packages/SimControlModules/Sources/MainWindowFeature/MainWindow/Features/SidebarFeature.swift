import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

@Reducer
public struct SidebarFeature {
  @ObservableState
  public struct State: Equatable {
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

  public enum Action: Equatable {}

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
