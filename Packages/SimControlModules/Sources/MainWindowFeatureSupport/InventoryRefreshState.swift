/// Describes the current simulator inventory refresh lifecycle.
public enum InventoryRefreshState: Equatable {
  case idle
  case refreshing
  case failed(diagnostic: String)
}
