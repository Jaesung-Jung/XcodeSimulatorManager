import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

/// Coordinates sidebar inventory state.
@Reducer
public struct SidebarFeature {
  /// Creates the sidebar reducer.
  public init() {}

  /// State rendered by the sidebar.
  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState

    /// Creates sidebar state from inventory snapshot and refresh state.
    public init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
    }
  }

  /// User actions emitted by the sidebar feature.
  public enum Action: Equatable {}

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
