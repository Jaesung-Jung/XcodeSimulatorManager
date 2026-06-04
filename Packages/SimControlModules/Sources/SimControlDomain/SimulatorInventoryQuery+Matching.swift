import Foundation

extension SimulatorInventoryQuery {
  func matches(_ query: String, in candidates: [String]) -> Bool {
    candidates.contains {
      $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
  }

  func same(_ candidate: String, _ query: String) -> Bool {
    candidate.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
  }

  func ordered(
    _ comparison: ComparisonResult,
    direction: SimulatorFilters.SortDirection
  ) -> Bool {
    switch direction {
    case .ascending:
      comparison == .orderedAscending
    case .descending:
      comparison == .orderedDescending
    }
  }

  func compare<T: Comparable>(_ first: T, _ second: T) -> ComparisonResult {
    if first < second {
      return .orderedAscending
    }

    if first > second {
      return .orderedDescending
    }

    return .orderedSame
  }
}
