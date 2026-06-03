import Foundation

// MARK: - MainWindowFeature Helpers

extension MainWindowFeature {
  func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }
}
