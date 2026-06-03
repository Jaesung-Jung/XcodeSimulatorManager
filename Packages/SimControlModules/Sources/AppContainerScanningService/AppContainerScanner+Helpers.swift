import Foundation
import SimControlDomain

extension AppContainerScanner {
  func installedAppSort(_ first: InstalledApp, _ second: InstalledApp) -> Bool {
    if first.displayName.localizedStandardCompare(second.displayName) == .orderedSame {
      return first.bundleID.localizedStandardCompare(second.bundleID) == .orderedAscending
    }

    return first.displayName.localizedStandardCompare(second.displayName) == .orderedAscending
  }

  func isSystemBundleID(_ bundleID: String) -> Bool {
    bundleID == "com.apple.Preferences" || bundleID.hasPrefix("com.apple.")
  }

  func isSystemAppGroupID(_ groupID: String) -> Bool {
    groupID.hasPrefix("group.com.apple.")
      || groupID.hasPrefix("com.apple.")
      || groupID.contains(".groups.com.apple.")
  }

  func nonEmpty(_ value: String?) -> String? {
    guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmedValue.isEmpty
    else {
      return nil
    }

    return trimmedValue
  }

  func fileWarning(
    id: String,
    message: String,
    relatedID: String?,
    error: Error
  ) -> SimulatorWarning {
    let category: SimulatorWarning.Category = isPermissionError(error) ? .permissions : .filesystem
    return warning(
      id: id,
      severity: .warning,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }

  func isPermissionError(_ error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain,
       nsError.code == CocoaError.Code.fileReadNoPermission.rawValue {
      return true
    }

    if nsError.domain == NSPOSIXErrorDomain,
       nsError.code == Int(EACCES) || nsError.code == Int(EPERM) {
      return true
    }

    return false
  }

  func warning(
    id: String,
    severity: SimulatorWarning.Severity,
    category: SimulatorWarning.Category,
    message: String,
    relatedID: String?
  ) -> SimulatorWarning {
    SimulatorWarning(
      id: id,
      severity: severity,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }
}
