import Foundation
import SimControlDomain
import Testing

struct SimulatorInventoryQueryTests {
  @Test
  func visibleDevicesRespectSidebarSearchSortAndBookmarks() {
    let alphaDevice = InventoryQueryFixtures.makeDevice(id: "DEVICE-A", name: "Alpha")
    let zedDevice = InventoryQueryFixtures.makeDevice(id: "DEVICE-Z", name: "Zed")
    let watchDevice = InventoryQueryFixtures.makeDevice(
      id: "WATCH-1",
      name: "Apple Watch",
      runtimeID: InventoryQueryFixtures.watchRuntime.id,
      deviceTypeID: InventoryQueryFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let app = InventoryQueryFixtures.makeInstalledApp(
      deviceID: alphaDevice.id,
      bundleID: "com.example.alpha"
    )
    let warning = SimulatorWarning(
      id: "device-warning",
      severity: .warning,
      category: .device,
      message: "Device warning",
      relatedID: zedDevice.id
    )
    let snapshot = InventoryQueryFixtures.makeSnapshot(
      runtimes: [
        InventoryQueryFixtures.runtime,
        InventoryQueryFixtures.watchRuntime
      ],
      deviceTypes: [
        InventoryQueryFixtures.deviceType,
        InventoryQueryFixtures.watchDeviceType
      ],
      devices: [
        zedDevice,
        alphaDevice,
        watchDevice
      ],
      installedAppsByDeviceID: [
        alphaDevice.id: [app]
      ],
      warnings: [warning]
    )

    var filters = SimulatorFilters(sidebarScope: .warnings)
    var query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleDevices().map(\.id) == [zedDevice.id])

    filters = SimulatorFilters(
      searchQuery: "com.example.alpha",
      pinnedDeviceIDs: [zedDevice.id]
    )
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleDevices().map(\.id) == [alphaDevice.id])

    filters = SimulatorFilters(pinnedDeviceIDs: [zedDevice.id])
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleDevices().map(\.id) == [
      alphaDevice.id,
      watchDevice.id,
      zedDevice.id
    ])
  }

  @Test
  func visibleAppsRespectSystemPresenceSearchSortAndBookmarks() {
    let device = InventoryQueryFixtures.device
    let appGroup = AppGroupContainer(
      id: "\(device.id):group.com.example.shared",
      groupID: "group.com.example.shared",
      path: URL(fileURLWithPath: "/tmp/group")
    )
    let alphaApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.alpha",
      displayName: "Alpha"
    )
    let groupApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.group",
      displayName: "Group",
      appGroups: [appGroup]
    )
    let databaseApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.database",
      displayName: "Database",
      databaseFiles: [URL(fileURLWithPath: "/tmp/database.sqlite")]
    )
    let systemApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.apple.Preferences",
      displayName: "Settings",
      isSystemApp: true
    )
    let hiddenSystemApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.apple.HiddenService",
      displayName: "Hidden Service",
      isSystemApp: true,
      isHiddenSystemApp: true
    )
    let snapshot = InventoryQueryFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        device.id: [
          hiddenSystemApp,
          systemApp,
          groupApp,
          databaseApp,
          alphaApp
        ]
      ]
    )

    var filters = SimulatorFilters()
    var query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id).contains(systemApp.id))
    #expect(query.visibleApps(for: device.id).map(\.id).contains(hiddenSystemApp.id) == false)

    filters = SimulatorFilters(showsHiddenSystemApps: true)
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id).contains(hiddenSystemApp.id))

    filters = SimulatorFilters(appSystemFilter: .all, appGroupFilter: .present)
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id) == [groupApp.id])

    filters = SimulatorFilters(appSystemFilter: .all, appDatabaseFilter: .present)
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id) == [databaseApp.id])

    filters = SimulatorFilters(
      searchQuery: "sqlite",
      appSystemFilter: .all
    )
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id) == [databaseApp.id])

    filters = SimulatorFilters(
      appSystemFilter: .all,
      appSort: .name,
      pinnedAppIDs: [systemApp.id]
    )
    query = SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    #expect(query.visibleApps(for: device.id).map(\.id) == [
      alphaApp.id,
      databaseApp.id,
      groupApp.id,
      systemApp.id
    ])
  }

  @Test
  func exactSearchAndSelectionReconciliationPreferValidVisibleTargets() {
    let firstDevice = InventoryQueryFixtures.device
    let secondDevice = InventoryQueryFixtures.makeDevice(id: "DEVICE-2", name: "Second Device")
    let firstApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: firstDevice.id,
      bundleID: "com.example.first"
    )
    let secondApp = InventoryQueryFixtures.makeInstalledApp(
      deviceID: secondDevice.id,
      bundleID: "com.example.second"
    )
    let snapshot = InventoryQueryFixtures.makeSnapshot(
      devices: [
        firstDevice,
        secondDevice
      ],
      installedAppsByDeviceID: [
        firstDevice.id: [firstApp],
        secondDevice.id: [secondApp]
      ]
    )

    let query = SimulatorInventoryQuery(snapshot: snapshot, filters: SimulatorFilters())

    #expect(query.exactSearchTarget() == SimulatorInventorySelection())

    let deviceSearch = SimulatorInventoryQuery(
      snapshot: snapshot,
      filters: SimulatorFilters(searchQuery: secondDevice.udid.lowercased())
    )
    #expect(deviceSearch.exactSearchTarget() == SimulatorInventorySelection(
      deviceID: secondDevice.id,
      appID: nil
    ))

    let appSearch = SimulatorInventoryQuery(
      snapshot: snapshot,
      filters: SimulatorFilters(searchQuery: firstApp.bundleID.uppercased())
    )
    #expect(appSearch.exactSearchTarget() == SimulatorInventorySelection(
      deviceID: firstDevice.id,
      appID: firstApp.id
    ))

    #expect(query.selectionAfterApplyingSnapshot(
      current: SimulatorInventorySelection(deviceID: firstDevice.id, appID: firstApp.id),
      preferred: SimulatorInventorySelection(deviceID: secondDevice.id, appID: nil)
    ) == SimulatorInventorySelection(deviceID: secondDevice.id, appID: nil))

    let filteredQuery = SimulatorInventoryQuery(
      snapshot: snapshot,
      filters: SimulatorFilters(searchQuery: secondDevice.name)
    )
    #expect(filteredQuery.selectionAfterFilterChange(
      current: SimulatorInventorySelection(deviceID: firstDevice.id, appID: firstApp.id),
      preferred: SimulatorInventorySelection()
    ) == SimulatorInventorySelection(deviceID: secondDevice.id, appID: nil))
  }

  @Test
  func selectedInventoryDetailsProjectRuntimeTypePairAndCompatibleTargets() {
    let phone = InventoryQueryFixtures.makeDevice(
      id: "PHONE-1",
      name: "Phone",
      state: .booted
    )
    let compatiblePhone = InventoryQueryFixtures.makeDevice(
      id: "PHONE-2",
      name: "Compatible Phone",
      state: .shutdown
    )
    let unavailablePhone = InventoryQueryFixtures.makeDevice(
      id: "PHONE-3",
      name: "Unavailable Phone",
      state: .shutdown,
      isAvailable: false
    )
    let watch = InventoryQueryFixtures.makeDevice(
      id: "WATCH-1",
      name: "Watch",
      state: .shutdown,
      runtimeID: InventoryQueryFixtures.watchRuntime.id,
      deviceTypeID: InventoryQueryFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let pair = DevicePair(
      id: "PAIR-1",
      phoneDeviceID: phone.id,
      watchDeviceID: watch.id,
      state: .active
    )
    let snapshot = InventoryQueryFixtures.makeSnapshot(
      runtimes: [
        InventoryQueryFixtures.runtime,
        InventoryQueryFixtures.watchRuntime
      ],
      deviceTypes: [
        InventoryQueryFixtures.deviceType,
        InventoryQueryFixtures.watchDeviceType
      ],
      devices: [
        phone,
        compatiblePhone,
        unavailablePhone,
        watch
      ],
      pairs: [pair]
    )
    let query = SimulatorInventoryQuery(snapshot: snapshot, filters: SimulatorFilters())

    #expect(query.device(id: phone.id) == phone)
    #expect(query.runtime(for: phone) == InventoryQueryFixtures.runtime)
    #expect(query.deviceType(for: phone) == InventoryQueryFixtures.deviceType)
    #expect(query.pairSummary(for: watch) == SimulatorInventoryPairSummary(
      id: pair.id,
      phoneDeviceID: phone.id,
      phoneName: phone.name,
      phoneUDID: phone.udid,
      watchDeviceID: watch.id,
      watchName: watch.name,
      watchUDID: watch.udid,
      state: pair.state
    ))
    #expect(query.compatibleInstallTargetCount(for: phone) == 1)
  }
}

extension SimulatorInventoryQueryTests {
  private enum InventoryQueryFixtures {
    static let runtime = SimulatorRuntime(
      id: "runtime-ios",
      name: "iOS 26.4",
      version: "26.4",
      buildVersion: "23E244",
      platform: .iOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type-iphone"]
    )

    static let deviceType = SimulatorDeviceType(
      id: "device-type-iphone",
      name: "iPhone 17 Pro",
      productFamily: "iPhone",
      modelIdentifier: "iPhone18,1"
    )

    static let watchRuntime = SimulatorRuntime(
      id: "runtime-watchos",
      name: "watchOS 26.4",
      version: "26.4",
      buildVersion: "23T244",
      platform: .watchOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type-watch"]
    )

    static let watchDeviceType = SimulatorDeviceType(
      id: "device-type-watch",
      name: "Apple Watch Series 11",
      productFamily: "Apple Watch",
      modelIdentifier: "Watch7,1"
    )

    static let device = makeDevice(id: "DEVICE-1")

    static func makeSnapshot(
      generatedAt: Date = Date(timeIntervalSince1970: 1_000),
      runtimes: [SimulatorRuntime] = [runtime],
      deviceTypes: [SimulatorDeviceType] = [deviceType],
      devices: [SimulatorDevice] = [device],
      pairs: [DevicePair] = [],
      installedAppsByDeviceID: [String: [InstalledApp]] = [:],
      warnings: [SimulatorWarning] = []
    ) -> SimulatorSnapshot {
      SimulatorSnapshot(
        generatedAt: generatedAt,
        xcode: XcodeSelection(
          developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
          version: nil,
          isValid: true
        ),
        runtimes: runtimes,
        deviceTypes: deviceTypes,
        devices: devices,
        pairs: pairs,
        installedAppsByDeviceID: installedAppsByDeviceID,
        warnings: warnings
      )
    }

    static func makeDevice(
      id: String,
      name: String? = nil,
      state: SimulatorDevice.State = .shutdown,
      isAvailable: Bool = true,
      runtimeID: String = runtime.id,
      deviceTypeID: String = deviceType.id,
      platform: SimulatorPlatform = .iOS
    ) -> SimulatorDevice {
      SimulatorDevice(
        id: id,
        udid: id,
        name: name ?? "Device \(id)",
        runtimeID: runtimeID,
        deviceTypeID: deviceTypeID,
        platform: platform,
        state: state,
        isAvailable: isAvailable,
        dataPath: URL(fileURLWithPath: "/tmp/\(id)/data"),
        logPath: URL(fileURLWithPath: "/tmp/\(id)/logs"),
        lastBootedAt: nil,
        dataPathSize: nil
      )
    }

    static func makeInstalledApp(
      deviceID: String,
      bundleID: String,
      displayName: String = "Example",
      appGroups: [AppGroupContainer] = [],
      isSystemApp: Bool = false,
      isHiddenSystemApp: Bool = false,
      databaseFiles: [URL] = [],
      dataContainerSize: Int64? = nil
    ) -> InstalledApp {
      InstalledApp(
        id: "\(deviceID):\(bundleID)",
        bundleID: bundleID,
        displayName: displayName,
        version: "1.0",
        build: "100",
        deviceID: deviceID,
        bundleContainer: URL(fileURLWithPath: "/tmp/\(deviceID)/\(bundleID)/bundle"),
        dataContainer: URL(fileURLWithPath: "/tmp/\(deviceID)/\(bundleID)/data"),
        appBundlePath: URL(fileURLWithPath: "/tmp/\(deviceID)/\(bundleID)/Example.app"),
        appGroups: appGroups,
        iconPath: nil,
        isSystemApp: isSystemApp,
        isHiddenSystemApp: isHiddenSystemApp,
        databaseFiles: databaseFiles,
        dataContainerSize: dataContainerSize
      )
    }
  }
}
