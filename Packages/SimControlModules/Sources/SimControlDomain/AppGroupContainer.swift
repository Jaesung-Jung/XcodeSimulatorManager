import Foundation

/// A CoreSimulator App Group container associated with an installed app.
///
/// App Group containers are discovered from simulator data folders and are
/// represented as value data only. Opening, copying, and permission checks for
/// the path are handled by service-layer code.
public struct AppGroupContainer: Identifiable, Equatable, Hashable {
  /// A stable identifier for the App Group container entry.
  public let id: String

  /// The App Group identifier, such as `group.com.example.shared`.
  public let groupID: String

  /// The filesystem URL for the App Group container.
  public let path: URL

  /// Creates an App Group container value.
  public init(id: String, groupID: String, path: URL) {
    self.id = id
    self.groupID = groupID
    self.path = path
  }
}
