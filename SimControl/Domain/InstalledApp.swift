import Foundation

/// An app installation discovered on a simulator device.
///
/// `InstalledApp` combines app metadata read from the installed bundle with the
/// CoreSimulator container locations that SimControl can present or act on. It
/// stores paths as URLs but does not perform filesystem operations itself.
struct InstalledApp: Identifiable, Equatable, Hashable {
  /// A stable identifier for this installed app entry.
  let id: String

  /// The app bundle identifier.
  let bundleID: String

  /// The display name chosen for presentation.
  let displayName: String

  /// The app short version string, when available.
  let version: String?

  /// The app build version string, when available.
  let build: String?

  /// The identifier of the simulator device that contains this app.
  let deviceID: String

  /// The bundle container URL, when known.
  let bundleContainer: URL?

  /// The data container URL, when known.
  let dataContainer: URL?

  /// The installed `.app` bundle URL, when known.
  let appBundlePath: URL?

  /// App Group containers associated with the app.
  let appGroups: [AppGroupContainer]

  /// A resolved icon file URL, when one has been discovered.
  let iconPath: URL?

  /// Indicates whether the bundle identifier belongs to an Apple/system app.
  let isSystemApp: Bool

  /// Detected database files inside the app data container.
  let databaseFiles: [URL]

  /// The calculated data container size in bytes, when available.
  let dataContainerSize: Int64?

  init(
    id: String,
    bundleID: String,
    displayName: String,
    version: String?,
    build: String?,
    deviceID: String,
    bundleContainer: URL?,
    dataContainer: URL?,
    appBundlePath: URL?,
    appGroups: [AppGroupContainer],
    iconPath: URL?,
    isSystemApp: Bool = false,
    databaseFiles: [URL] = [],
    dataContainerSize: Int64? = nil
  ) {
    self.id = id
    self.bundleID = bundleID
    self.displayName = displayName
    self.version = version
    self.build = build
    self.deviceID = deviceID
    self.bundleContainer = bundleContainer
    self.dataContainer = dataContainer
    self.appBundlePath = appBundlePath
    self.appGroups = appGroups
    self.iconPath = iconPath
    self.isSystemApp = isSystemApp
    self.databaseFiles = databaseFiles
    self.dataContainerSize = dataContainerSize
  }
}
