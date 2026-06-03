import Foundation
import SimControlDomain

extension AppContainerScanner {
  func readPropertyList(
    at url: URL,
    device: SimulatorDevice,
    warningID: String,
    warningMessage: String,
    warnings: inout [SimulatorWarning]
  ) -> [String: Any]? {
    guard fileManager.fileExists(atPath: url.path) else {
      warnings.append(
        warning(
          id: "\(warningID)-missing",
          severity: .warning,
          category: .app,
          message: warningMessage,
          relatedID: device.id
        )
      )
      return nil
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      warnings.append(fileWarning(
        id: warningID,
        message: "\(warningMessage) \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }

    do {
      let propertyList = try PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      )

      guard let dictionary = propertyList as? [String: Any] else {
        warnings.append(
          warning(
            id: warningID,
            severity: .warning,
            category: .parsing,
            message: warningMessage,
            relatedID: device.id
          )
        )
        return nil
      }

      return dictionary
    } catch {
      warnings.append(
        warning(
          id: warningID,
          severity: .warning,
          category: .parsing,
          message: "\(warningMessage) \(error.localizedDescription)",
          relatedID: device.id
        )
      )
      return nil
    }
  }
}
