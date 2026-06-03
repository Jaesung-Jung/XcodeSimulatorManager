import Foundation

/// A CoreSimulator App Group container associated with an installed app.
///
/// App Group containers are discovered from simulator data folders and are
/// represented as value data only. Opening, copying, and permission checks for
/// the path are handled by service-layer code.
struct AppGroupContainer: Identifiable, Equatable, Hashable {
  /// A stable identifier for the App Group container entry.
  let id: String

  /// The App Group identifier, such as `group.com.example.shared`.
  let groupID: String

  /// The filesystem URL for the App Group container.
  let path: URL
}
