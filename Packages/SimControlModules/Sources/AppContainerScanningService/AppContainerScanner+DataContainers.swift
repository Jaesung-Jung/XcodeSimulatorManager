import Foundation
import SimControlDomain

extension AppContainerScanner {
  static let databaseFileExtensions = Set(["db", "realm", "sqlite", "sqlite3"])

  func dataContainerDetails(
    at dataContainer: URL?,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> DataContainerDetails {
    guard let dataContainer else {
      return DataContainerDetails(databaseFiles: [], size: nil)
    }

    do {
      let subpaths = try fileManager.subpathsOfDirectory(atPath: dataContainer.path)
      var databaseFiles: [URL] = []
      var size: Int64 = 0

      for subpath in subpaths {
        let url = dataContainer.appendingPathComponent(subpath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
          continue
        }

        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues?.fileSize {
          size += Int64(fileSize)
        }

        if isDatabaseFile(url) {
          databaseFiles.append(url)
        }
      }

      return DataContainerDetails(
        databaseFiles: databaseFiles.sorted {
          $0.path.localizedStandardCompare($1.path) == .orderedAscending
        },
        size: size
      )
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-data-\(dataContainer.lastPathComponent)-scan-failed",
        message: "App data container \(dataContainer.lastPathComponent) in \(device.name) could not be scanned: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return DataContainerDetails(databaseFiles: [], size: nil)
    }
  }

  func isDatabaseFile(_ url: URL) -> Bool {
    let fileExtension = url.pathExtension.lowercased()
    if Self.databaseFileExtensions.contains(fileExtension) {
      return true
    }

    let fileName = url.lastPathComponent.lowercased()
    return fileName.hasSuffix(".db-shm")
      || fileName.hasSuffix(".db-wal")
      || fileName.hasSuffix(".sqlite-shm")
      || fileName.hasSuffix(".sqlite-wal")
  }
}
