import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

@Reducer
public struct SidebarFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState

    public init(
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
