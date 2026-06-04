import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import SimControlDomain
import WorkspaceFeature

/// Coordinates menu bar presentation state and selection actions.
@Reducer
public struct MenuBarFeature {
  /// Creates the menu bar reducer.
  public init() {}

  /// State rendered by the menu bar extra.
  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState
    public var filters: SimulatorFilters

    /// Creates menu bar state from snapshot, refresh state, and filters.
    public init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      filters: SimulatorFilters = SimulatorFilters()
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.filters = filters
    }

    /// Creates menu bar state projected from workspace state.
    public init(workspace: WorkspaceFeature.State) {
      self.init(
        snapshot: workspace.snapshot,
        refreshState: workspace.refreshState,
        filters: workspace.filters
      )
    }
  }

  /// User actions emitted by the menu bar extra.
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
