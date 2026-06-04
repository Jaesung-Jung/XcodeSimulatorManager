import Foundation
import SimControlDomain

extension AppContainerScanner {
  func containerDirectories(
    at root: URL,
    device: SimulatorDevice,
    role: String,
    warningIDRole: String,
    warnings: inout [SimulatorWarning]
  ) -> [URL]? {
    guard directoryExists(at: root) else {
      warnings.append(
        warning(
          id: "apps-\(device.id)-missing-\(warningIDRole)-container",
          severity: .warning,
          category: .filesystem,
          message: "Device \(device.name) is missing its \(role) container folder.",
          relatedID: device.id
        )
      )
      return nil
    }

    do {
      let contents = try fileManager.contentsOfDirectory(
        at: root,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsPackageDescendants]
      )
      return contents
        .filter { directoryExists(at: $0) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-read-\(warningIDRole)-container-failed",
        message: "Device \(device.name) \(role) containers could not be read: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }
  }

  func appBundle(
    in bundleContainer: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> URL? {
    do {
      let contents = try fileManager.contentsOfDirectory(
        at: bundleContainer,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )
      let appBundles = contents
        .filter { $0.pathExtension == "app" && directoryExists(at: $0) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

      guard let appBundle = appBundles.first else {
        warnings.append(
          warning(
            id: "apps-\(device.id)-bundle-\(bundleContainer.lastPathComponent)-missing-app-bundle",
            severity: .warning,
            category: .app,
            message: "A bundle container in \(device.name) does not contain an app bundle and was skipped.",
            relatedID: device.id
          )
        )
        return nil
      }

      return appBundle
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-bundle-\(bundleContainer.lastPathComponent)-read-failed",
        message: "A bundle container in \(device.name) could not be read: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }
  }

  func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
  }
}
