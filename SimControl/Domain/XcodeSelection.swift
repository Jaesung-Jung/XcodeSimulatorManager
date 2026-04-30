import Foundation

/// The active Xcode developer directory and validation state.
///
/// `XcodeSelection` captures the environment used to run `xcrun` and `simctl`.
/// It is a value description only; validation and command execution remain in
/// the service layer.
struct XcodeSelection: Equatable, Hashable {
  /// The selected Xcode developer directory URL, when known.
  let developerPath: URL?

  /// The detected Xcode version, when available.
  let version: String?

  /// Indicates whether the selected Xcode environment is usable.
  let isValid: Bool
}
