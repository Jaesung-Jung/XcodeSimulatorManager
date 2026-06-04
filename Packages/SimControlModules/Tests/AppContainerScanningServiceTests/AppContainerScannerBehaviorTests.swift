import Foundation
import SimControlDomain
import Testing
@testable import AppContainerScanningService

@Suite
struct AppContainerScannerTests {
  @Test func scansBundleDataAndAppGroupContainersForShutdownDevice() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/BUNDLE-1",
      isDirectory: true
    )
    let dataContainer = dataPath.appendingPathComponent(
      "Containers/Data/Application/DATA-1",
      isDirectory: true
    )
    let appGroupContainer = dataPath.appendingPathComponent(
      "Containers/Shared/AppGroup/GROUP-1",
      isDirectory: true
    )
    let appBundle = bundleContainer.appendingPathComponent("Example.app", isDirectory: true)
    let iconPath = appBundle.appendingPathComponent("AppIcon60x60@2x.png")
    let databasePath = dataContainer.appendingPathComponent("Documents/Cache.sqlite")
    let databaseWriteAheadLogPath = dataContainer.appendingPathComponent("Documents/Cache.sqlite-wal")
    let realmPath = dataContainer.appendingPathComponent("Library/Model.realm")

    try createDirectory(appBundle)
    try createDirectory(dataContainer)
    try createDirectory(appGroupContainer)
    try createDirectory(databasePath.deletingLastPathComponent())
    try createDirectory(realmPath.deletingLastPathComponent())
    try writeMetadata(bundleID: "com.example.app", to: bundleContainer)
    try writeMetadata(bundleID: "com.example.app", to: dataContainer)
    try writeMetadata(bundleID: "group.com.example.shared", to: appGroupContainer)
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.example.app",
        "CFBundleDisplayName": "Example App",
        "CFBundleShortVersionString": "1.2.3",
        "CFBundleVersion": "123",
        "CFBundleIcons": [
          "CFBundlePrimaryIcon": [
            "CFBundleIconFiles": ["AppIcon60x60"]
          ]
        ]
      ],
      to: appBundle
    )
    try writePropertyList(
      [
        "com.apple.security.application-groups": ["group.com.example.shared"]
      ],
      to: appBundle.appendingPathComponent("archived-expanded-entitlements.xcent")
    )
    try Data().write(to: iconPath)
    try Data("sqlite".utf8).write(to: databasePath)
    try Data("wal".utf8).write(to: databaseWriteAheadLogPath)
    try Data("realm".utf8).write(to: realmPath)
    let expectedDataContainerSize = try directorySize(dataContainer)

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath, state: .shutdown))

    #expect(result.warnings.isEmpty)
    let app = try #require(result.apps.first)
    #expect(app.bundleID == "com.example.app")
    #expect(app.displayName == "Example App")
    #expect(app.version == "1.2.3")
    #expect(app.build == "123")
    #expect(app.bundleContainer?.resolvingSymlinksInPath() == bundleContainer.resolvingSymlinksInPath())
    #expect(app.dataContainer?.resolvingSymlinksInPath() == dataContainer.resolvingSymlinksInPath())
    #expect(app.appBundlePath?.resolvingSymlinksInPath() == appBundle.resolvingSymlinksInPath())
    #expect(app.iconPath?.resolvingSymlinksInPath() == iconPath.resolvingSymlinksInPath())
    #expect(Set(app.databaseFiles.map(\.lastPathComponent)) == Set(["Cache.sqlite", "Cache.sqlite-wal", "Model.realm"]))
    #expect(app.dataContainerSize == expectedDataContainerSize)
    let normalizedAppGroups = app.appGroups.map { appGroup in
      AppGroupContainer(
        id: appGroup.id,
        groupID: appGroup.groupID,
        path: appGroup.path.resolvingSymlinksInPath()
      )
    }
    #expect(normalizedAppGroups == [
      AppGroupContainer(
        id: "DEVICE-1:group.com.example.shared",
        groupID: "group.com.example.shared",
        path: appGroupContainer.resolvingSymlinksInPath()
      )
    ])
  }

  @Test func includesSystemAppsAndMarksThemByDefault() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/SYSTEM-BUNDLE",
      isDirectory: true
    )
    let appBundle = bundleContainer.appendingPathComponent("Preferences.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeMetadata(bundleID: "com.apple.Preferences", to: bundleContainer)
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.Preferences",
        "CFBundleName": "Settings"
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath))

    let app = try #require(result.apps.first)
    #expect(app.bundleID == "com.apple.Preferences")
    #expect(app.isSystemApp)
  }

  @Test func scansSystemAppsFromRuntimeRoot() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let runtimeRoot = temporaryDirectory.url.appendingPathComponent("RuntimeRoot", isDirectory: true)
    let appBundle = runtimeRoot.appendingPathComponent("Applications/Preferences.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Bundle/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.Preferences",
        "CFBundleName": "Settings"
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath), runtimeRoot: runtimeRoot)

    let app = try #require(result.apps.first)
    #expect(app.bundleID == "com.apple.Preferences")
    #expect(app.displayName == "Settings")
    #expect(app.appBundlePath?.resolvingSymlinksInPath() == appBundle.resolvingSymlinksInPath())
    #expect(app.isSystemApp)
  }

  @Test func marksRuntimeSystemAppsMissingFromHomeScreenAsHidden() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let runtimeRoot = temporaryDirectory.url.appendingPathComponent("RuntimeRoot", isDirectory: true)
    let settingsBundle = runtimeRoot.appendingPathComponent("Applications/Preferences.app", isDirectory: true)
    let emojiBundle = runtimeRoot.appendingPathComponent("Applications/EmojiPoster.app", isDirectory: true)

    try createDirectory(settingsBundle)
    try createDirectory(emojiBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Bundle/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Library/SpringBoard", isDirectory: true))
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.Preferences",
        "CFBundleName": "Settings"
      ],
      to: settingsBundle
    )
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.EmojiPoster",
        "CFBundleDisplayName": "Emoji",
        "CFBundleName": "EmojiPoster"
      ],
      to: emojiBundle
    )
    try writePropertyList(
      [
        "buttonBar": ["com.apple.mobilesafari"],
        "iconLists": [
          [
            "com.apple.Preferences",
            [
              "displayName": "Utilities",
              "iconLists": [
                [
                  "com.apple.Passwords"
                ]
              ],
              "listType": "folder"
            ]
          ]
        ]
      ],
      to: dataPath.appendingPathComponent("Library/SpringBoard/IconState.plist")
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath), runtimeRoot: runtimeRoot)

    let appsByBundleID = Dictionary(uniqueKeysWithValues: result.apps.map { ($0.bundleID, $0) })
    let settings = try #require(appsByBundleID["com.apple.Preferences"])
    let emoji = try #require(appsByBundleID["com.apple.EmojiPoster"])
    #expect(!settings.isHiddenSystemApp)
    #expect(emoji.isHiddenSystemApp)
  }

  @Test func marksHiddenRuntimeSystemApps() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let runtimeRoot = temporaryDirectory.url.appendingPathComponent("RuntimeRoot", isDirectory: true)
    let appBundle = runtimeRoot.appendingPathComponent("Applications/HiddenService.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Bundle/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.HiddenService",
        "CFBundleName": "Hidden Service",
        "SBAppTags": ["hidden"]
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath), runtimeRoot: runtimeRoot)

    let app = try #require(result.apps.first)
    #expect(app.bundleID == "com.apple.HiddenService")
    #expect(app.isSystemApp)
    #expect(app.isHiddenSystemApp)
  }

  @Test func hidesSystemAppsWhenConfigured() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/SYSTEM-BUNDLE",
      isDirectory: true
    )
    let appBundle = bundleContainer.appendingPathComponent("Preferences.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeMetadata(bundleID: "com.apple.Preferences", to: bundleContainer)
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.apple.Preferences",
        "CFBundleName": "Settings"
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner(hidesSystemApps: true)
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath))

    #expect(result.apps.isEmpty)
  }

  @Test func missingBundleMetadataFallsBackToInfoPlistAndWarns() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/BUNDLE-1",
      isDirectory: true
    )
    let appBundle = bundleContainer.appendingPathComponent("Partial.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.example.partial",
        "CFBundleName": "Partial"
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath))

    #expect(result.apps.map(\.bundleID) == ["com.example.partial"])
    #expect(result.warnings.contains {
      $0.id == "apps-DEVICE-1-bundle-BUNDLE-1-missing-metadata"
    })
  }

  @Test func partialInstallWithoutAppBundleWarnsAndSkipsEntry() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/BUNDLE-1",
      isDirectory: true
    )

    try createDirectory(bundleContainer)
    try createDirectory(dataPath.appendingPathComponent("Containers/Data/Application", isDirectory: true))
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeMetadata(bundleID: "com.example.partial", to: bundleContainer)

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath))

    #expect(result.apps.isEmpty)
    #expect(result.warnings.contains {
      $0.id == "apps-DEVICE-1-bundle-BUNDLE-1-missing-app-bundle"
    })
  }

  @Test func malformedDataContainerMetadataWarnsButKeepsBundleApp() throws {
    let temporaryDirectory = try TemporaryDirectory()
    let dataPath = temporaryDirectory.url.appendingPathComponent("DeviceData", isDirectory: true)
    let bundleContainer = dataPath.appendingPathComponent(
      "Containers/Bundle/Application/BUNDLE-1",
      isDirectory: true
    )
    let dataContainer = dataPath.appendingPathComponent(
      "Containers/Data/Application/DATA-1",
      isDirectory: true
    )
    let appBundle = bundleContainer.appendingPathComponent("Example.app", isDirectory: true)

    try createDirectory(appBundle)
    try createDirectory(dataContainer)
    try createDirectory(dataPath.appendingPathComponent("Containers/Shared/AppGroup", isDirectory: true))
    try writeMetadata(bundleID: "com.example.app", to: bundleContainer)
    try Data("not plist".utf8).write(
      to: dataContainer.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
    )
    try writeInfoPlist(
      [
        "CFBundleIdentifier": "com.example.app",
        "CFBundleName": "Example"
      ],
      to: appBundle
    )

    let scanner = AppContainerScanner()
    let result = scanner.scanInstalledApps(for: makeDevice(dataPath: dataPath))

    let app = try #require(result.apps.first)
    #expect(app.bundleID == "com.example.app")
    #expect(app.dataContainer == nil)
    #expect(result.warnings.contains {
      $0.id == "apps-DEVICE-1-data-DATA-1-malformed-metadata"
    })
  }

  private func makeDevice(
    dataPath: URL,
    state: SimulatorDevice.State = .booted
  ) -> SimulatorDevice {
    SimulatorDevice(
      id: "DEVICE-1",
      udid: "DEVICE-1",
      name: "iPhone 17 Pro",
      runtimeID: "runtime-ios",
      deviceTypeID: "device-type-iphone",
      platform: .iOS,
      state: state,
      isAvailable: true,
      dataPath: dataPath,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )
  }
}

private final class TemporaryDirectory {
  let url: URL

  init() throws {
    url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "SimControlTests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true
    )
  }

  deinit {
    try? FileManager.default.removeItem(at: url)
  }
}

private func createDirectory(_ url: URL) throws {
  try FileManager.default.createDirectory(
    at: url,
    withIntermediateDirectories: true
  )
}

private func writeMetadata(bundleID: String, to container: URL) throws {
  try writePropertyList(
    [
      "MCMMetadataIdentifier": bundleID
    ],
    to: container.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
  )
}

private func writeInfoPlist(_ values: [String: Any], to appBundle: URL) throws {
  try writePropertyList(
    values,
    to: appBundle.appendingPathComponent("Info.plist")
  )
}

private func writePropertyList(_ values: [String: Any], to url: URL) throws {
  let data = try PropertyListSerialization.data(
    fromPropertyList: values,
    format: .xml,
    options: 0
  )
  try data.write(to: url)
}

private func directorySize(_ url: URL) throws -> Int64 {
  let fileManager = FileManager.default
  let subpaths = try fileManager.subpathsOfDirectory(atPath: url.path)
  return try subpaths.reduce(Int64(0)) { size, subpath in
    let fileURL = url.appendingPathComponent(subpath)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
          !isDirectory.boolValue
    else {
      return size
    }

    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
    return size + Int64((attributes[.size] as? NSNumber)?.int64Value ?? 0)
  }
}
