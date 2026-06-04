import Foundation

extension AppContainerScanner {
  func readHomeScreenAppIDs(in dataPath: URL) -> Set<String>? {
    let iconStateURL = dataPath.appendingPathComponent("Library/SpringBoard/IconState.plist")
    guard fileManager.fileExists(atPath: iconStateURL.path),
          let data = try? Data(contentsOf: iconStateURL),
          let propertyList = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
          ),
          let iconState = propertyList as? [String: Any]
    else {
      return nil
    }

    var appIDs = Set<String>()
    collectHomeScreenAppIDs(from: iconState["buttonBar"], into: &appIDs)
    collectHomeScreenAppIDs(from: iconState["iconLists"], into: &appIDs)

    return appIDs.isEmpty ? nil : appIDs
  }

  func collectHomeScreenAppIDs(from value: Any?, into appIDs: inout Set<String>) {
    switch value {
    case let bundleID as String where bundleID.hasPrefix("com."):
      appIDs.insert(bundleID)

    case let values as [Any]:
      for value in values {
        collectHomeScreenAppIDs(from: value, into: &appIDs)
      }

    case let dictionary as [String: Any]:
      if dictionary["elementType"] as? String == "widget" {
        return
      }

      if let bundleID = dictionary["bundleIdentifier"] as? String {
        appIDs.insert(bundleID)
      }

      collectHomeScreenAppIDs(from: dictionary["iconLists"], into: &appIDs)
      collectHomeScreenAppIDs(from: dictionary["elements"], into: &appIDs)

    default:
      return
    }
  }
}
