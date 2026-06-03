import Foundation

/// The active Xcode developer directory and validation state.
///
/// `XcodeSelection` captures the environment used to run `xcrun` and `simctl`.
/// It is a value description only; validation and command execution remain in
/// the service layer.
public struct XcodeSelection: Equatable, Hashable {
  /// The selected Xcode developer directory URL, when known.
  public let developerPath: URL?

  /// The detected Xcode version, when available.
  public let version: String?

  /// Indicates whether the selected Xcode environment is usable.
  public let isValid: Bool

  /// Creates an Xcode selection value.
  public init(
    developerPath: URL?,
    version: String?,
    isValid: Bool
  ) {
    self.developerPath = developerPath
    self.version = version
    self.isValid = isValid
  }
}
