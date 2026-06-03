import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import SimControlDomain
import WorkspaceFeature

@Reducer
public struct MenuBarFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState
    public var filters: SimulatorFilters

    public init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      filters: SimulatorFilters = SimulatorFilters()
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.filters = filters
    }

    public init(workspace: WorkspaceFeature.State) {
      self.init(
        snapshot: workspace.snapshot,
        refreshState: workspace.refreshState,
        filters: workspace.filters
      )
    }
  }

  public enum Action: Equatable {
    case presented(at: Date)
    case refreshButtonTapped
    case openSimulatorAppButtonTapped
    case deviceSelected(String)
    case appSelected(deviceID: String, appID: String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
