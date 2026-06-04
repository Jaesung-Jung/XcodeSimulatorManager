import Foundation

// MARK: - AppContainerScanner.BundleMetadata

extension AppContainerScanner {
  struct BundleMetadata {
    let bundleID: String?
    let displayName: String?
    let version: String?
    let build: String?
    let iconPath: URL?
    let appGroupIDs: [String]
  }
}

// MARK: - AppContainerScanner.DataContainerDetails

extension AppContainerScanner {
  struct DataContainerDetails {
    let databaseFiles: [URL]
    let size: Int64?
  }
}
