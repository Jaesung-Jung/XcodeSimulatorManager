import Foundation
import SimControlDomain

extension AppContainerScanner {
  func readDefaultHomeScreenAppIDs(in runtimeRoot: URL?, for device: SimulatorDevice) -> Set<String>? {
    guard device.platform == .iOS,
          let springBoardBundle = runtimeRoot?.appendingPathComponent(
            "System/Library/CoreServices/SpringBoard.app",
            isDirectory: true
          )
    else {
      return nil
    }

    for fileName in defaultIconStateFileNames(for: device) {
      let iconStateURL = springBoardBundle.appendingPathComponent(fileName)
      guard fileManager.fileExists(atPath: iconStateURL.path),
            let data = try? Data(contentsOf: iconStateURL),
            let propertyList = try? PropertyListSerialization.propertyList(
              from: data,
              options: [],
              format: nil
            )
      else {
        continue
      }

      var appIDs = Set<String>()
      collectHomeScreenAppIDs(from: propertyList, into: &appIDs)
      if !appIDs.isEmpty {
        return appIDs
      }
    }

    return nil
  }

  func defaultIconStateFileNames(for device: SimulatorDevice) -> [String] {
    let deviceTypeID = device.deviceTypeID.lowercased()

    if deviceTypeID.contains("ipad") {
      return [
        "DefaultIconState~ipad.plist",
        "DefaultIconState.plist"
      ]
    }

    if deviceTypeID.contains("ipod") {
      return [
        "DefaultIconState-568h~ipod.plist",
        "DefaultIconState.plist"
      ]
    }

    return [
      "DefaultIconState~iphone.plist",
      "DefaultIconState.plist"
    ]
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

      collectHomeScreenAppIDs(from: dictionary["buttonBar"], into: &appIDs)
      collectHomeScreenAppIDs(from: dictionary["dockUtilities"], into: &appIDs)
      collectHomeScreenAppIDs(from: dictionary["iconLists"], into: &appIDs)
      collectHomeScreenAppIDs(from: dictionary["elements"], into: &appIDs)

    default:
      return
    }
  }
}
