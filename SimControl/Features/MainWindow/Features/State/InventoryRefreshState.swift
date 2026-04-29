enum InventoryRefreshState: Equatable {
  case idle
  case refreshing
  case failed(diagnostic: String)
}
