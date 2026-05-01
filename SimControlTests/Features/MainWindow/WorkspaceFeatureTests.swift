import ComposableArchitecture
import Foundation
import Testing

@testable import SimControl

@MainActor
struct WorkspaceFeatureTests {
  @Test
  func selectingDifferentDeviceClearsSelectedAppAndUpdatesInspector() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    let initialState = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded
    )

    let store = TestStore(initialState: initialState) {
      WorkspaceFeature()
    }

    await store.send(.deviceList(.selectionChanged(MainWindowTestFixtures.secondDevice.id))) {
      $0.deviceList = DeviceListFeature.State(
        devices: [
          MainWindowTestFixtures.device,
          MainWindowTestFixtures.secondDevice
        ],
        runtimeByID: [MainWindowTestFixtures.runtime.id: MainWindowTestFixtures.runtime],
        deviceTypeByID: [MainWindowTestFixtures.deviceType.id: MainWindowTestFixtures.deviceType],
        installedAppsByDeviceID: [
          MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
          MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
        ],
        installedAppsAvailability: .loaded,
        selectedDeviceID: MainWindowTestFixtures.secondDevice.id,
        filters: $0.filters,
        totalDeviceCount: 2
      )
      $0.deviceDetail = DeviceDetailFeature.State(
        device: MainWindowTestFixtures.secondDevice,
        runtime: MainWindowTestFixtures.runtime,
        deviceType: MainWindowTestFixtures.deviceType,
        installedApps: InstalledAppsFeature.State(
          apps: [MainWindowTestFixtures.secondApp],
          availability: .loaded,
          device: MainWindowTestFixtures.secondDevice,
          compatibleInstallTargetCount: 1,
          filters: $0.filters,
          allAppsCount: 1
        )
      )
      $0.inspector = InspectorFeature.State(
        snapshot: snapshot,
        device: MainWindowTestFixtures.secondDevice,
        runtime: MainWindowTestFixtures.runtime,
        deviceType: MainWindowTestFixtures.deviceType
      )
    }
  }

  @Test
  func selectingAppUpdatesDetailAndInspector() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )
    let initialState = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      installedAppsAvailability: .loaded
    )

    let store = TestStore(initialState: initialState) {
      WorkspaceFeature()
    }

    await store.send(.deviceDetail(.installedApps(.selectionChanged(MainWindowTestFixtures.app.id)))) {
      $0.filters.recordRecentAppID(MainWindowTestFixtures.app.id)
      $0.deviceDetail.installedApps.selectedAppID = MainWindowTestFixtures.app.id
      $0.deviceDetail.installedApps.filters = $0.filters
      $0.deviceDetail.developerTools.selectedAppID = MainWindowTestFixtures.app.id
      $0.deviceDetail.developerTools.pushBundleID = MainWindowTestFixtures.app.bundleID
      $0.deviceDetail.developerTools.privacyBundleID = MainWindowTestFixtures.app.bundleID
      $0.inspector.selectedApp = MainWindowTestFixtures.app
    }
  }

  @Test
  func applySnapshotUsesPreferredSelectedDeviceAndClearsSelectedApp() {
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: oldSnapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded
    )

    state.applySnapshot(
      newSnapshot,
      refreshState: .idle,
      commandResults: [],
      preferredSelectedDeviceID: MainWindowTestFixtures.secondDevice.id
    )

    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.secondDevice.id)
    #expect(state.deviceDetail.device == MainWindowTestFixtures.secondDevice)
    #expect(state.deviceDetail.installedApps.selectedAppID == nil)
    #expect(state.inspector.device == MainWindowTestFixtures.secondDevice)
  }

  @Test
  func applySnapshotFallsBackWhenPreferredSelectedDeviceIsMissing() {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    state.applySnapshot(
      snapshot,
      refreshState: .idle,
      commandResults: [],
      preferredSelectedDeviceID: "MISSING"
    )

    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.device.id)
    #expect(state.deviceDetail.device == MainWindowTestFixtures.device)
    #expect(state.inspector.device == MainWindowTestFixtures.device)
  }

  @Test
  func exactSearchNavigatesToMatchingDeviceAndApp() {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      installedAppsAvailability: .loaded
    )

    state.setSearchQuery(MainWindowTestFixtures.secondDevice.udid)

    #expect(state.filters.searchQuery == MainWindowTestFixtures.secondDevice.udid)
    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.secondDevice.id)
    #expect(state.deviceDetail.device == MainWindowTestFixtures.secondDevice)

    state.setSearchQuery(MainWindowTestFixtures.app.bundleID)

    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.device.id)
    #expect(state.deviceDetail.installedApps.selectedAppID == MainWindowTestFixtures.app.id)
    #expect(state.inspector.selectedApp == MainWindowTestFixtures.app)
  }

  @Test
  func filterChangeReconcilesHiddenDeviceAndKeepsSearchQuery() {
    let watchDevice = MainWindowTestFixtures.makeDevice(
      id: "WATCH-1",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        MainWindowTestFixtures.device,
        watchDevice
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    state.setSearchQuery("Device")
    state.setSidebarScope(.platform(.watchOS))

    #expect(state.filters.searchQuery == "Device")
    #expect(state.deviceList.devices.map(\.id) == [watchDevice.id])
    #expect(state.deviceList.selectedDeviceID == watchDevice.id)
    #expect(state.deviceDetail.device == watchDevice)
  }

  @Test
  func appFilterClearsHiddenSelectedApp() {
    let systemApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: MainWindowTestFixtures.device.id,
      bundleID: "com.apple.Preferences",
      isSystemApp: true
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [
          MainWindowTestFixtures.app,
          systemApp
        ]
      ]
    )
    var filters = SimulatorFilters()
    filters.appSystemFilter = .all
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: systemApp.id,
      installedAppsAvailability: .loaded,
      filters: filters
    )

    state.setAppSystemFilter(.user)

    #expect(state.deviceDetail.installedApps.apps.map(\.id) == [MainWindowTestFixtures.app.id])
    #expect(state.deviceDetail.installedApps.selectedAppID == nil)
  }

  @Test
  func pinnedSidebarScopeProjectsVisibleDevices() {
    var state = WorkspaceFeature.State(
      snapshot: MainWindowTestFixtures.makeSnapshot(
        devices: [
          MainWindowTestFixtures.device,
          MainWindowTestFixtures.secondDevice
        ]
      ),
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    state.togglePinnedDevice(id: MainWindowTestFixtures.secondDevice.id)
    state.setSidebarScope(.pinned)

    #expect(state.deviceList.devices.map(\.id) == [MainWindowTestFixtures.secondDevice.id])
    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.secondDevice.id)
  }

  @Test
  func warningsSidebarScopeProjectsDevicesWithRelatedWarnings() {
    let deviceWarning = SimulatorWarning(
      id: "device-warning",
      severity: .warning,
      category: .device,
      message: "Device warning",
      relatedID: MainWindowTestFixtures.secondDevice.id
    )
    let runtimeWarning = SimulatorWarning(
      id: "runtime-warning",
      severity: .warning,
      category: .runtime,
      message: "Runtime warning",
      relatedID: MainWindowTestFixtures.runtime.id
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      warnings: [
        deviceWarning,
        runtimeWarning
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    state.setSidebarScope(.warnings)

    #expect(state.deviceList.devices.map(\.id) == [MainWindowTestFixtures.secondDevice.id])
    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.secondDevice.id)
  }

  @Test
  func appSystemGroupDatabaseFiltersAndSortProjectVisibleApps() {
    let appGroup = AppGroupContainer(
      id: "\(MainWindowTestFixtures.device.id):group.com.example.shared",
      groupID: "group.com.example.shared",
      path: URL(fileURLWithPath: "/tmp/group")
    )
    let groupApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: MainWindowTestFixtures.device.id,
      bundleID: "com.example.group",
      appGroups: [appGroup]
    )
    let databaseApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: MainWindowTestFixtures.device.id,
      bundleID: "com.example.database",
      databaseFiles: [URL(fileURLWithPath: "/tmp/database.sqlite")],
      dataContainerSize: 128
    )
    let systemApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: MainWindowTestFixtures.device.id,
      bundleID: "com.apple.Preferences",
      isSystemApp: true
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [
          systemApp,
          groupApp,
          databaseApp
        ]
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      installedAppsAvailability: .loaded
    )

    #expect(state.deviceDetail.installedApps.apps.map(\.id).contains(systemApp.id) == false)

    state.setAppSystemFilter(.all)
    #expect(state.deviceDetail.installedApps.apps.map(\.id).contains(systemApp.id))

    state.setAppDatabaseFilter(.present)
    #expect(state.deviceDetail.installedApps.apps.map(\.id) == [databaseApp.id])

    state.setAppDatabaseFilter(.all)
    state.setAppGroupFilter(.present)
    #expect(state.deviceDetail.installedApps.apps.map(\.id) == [groupApp.id])

    state.setAppGroupFilter(.all)
    state.setAppSort(.bundleID)
    state.setAppSortDirection(.descending)
    #expect(state.deviceDetail.installedApps.apps.map(\.bundleID).first == "com.example.group")
  }

  @Test
  func deviceSortAndPinPriorityProjectVisibleDevices() {
    let alphaDevice = MainWindowTestFixtures.makeDevice(id: "DEVICE-A", name: "Alpha")
    let zedDevice = MainWindowTestFixtures.makeDevice(id: "DEVICE-Z", name: "Zed")
    var state = WorkspaceFeature.State(
      snapshot: MainWindowTestFixtures.makeSnapshot(
        devices: [
          zedDevice,
          alphaDevice
        ]
      )
    )

    #expect(state.deviceList.devices.map(\.name) == ["Alpha", "Zed"])

    state.setDeviceSortDirection(.descending)
    #expect(state.deviceList.devices.map(\.name) == ["Zed", "Alpha"])

    state.togglePinnedDevice(id: alphaDevice.id)
    #expect(state.deviceList.devices.map(\.id).first == alphaDevice.id)
  }

  @Test
  func refreshPreservesPinsSelectionAndFiltersWhenTargetsRemainVisible() {
    var filters = SimulatorFilters()
    filters.searchQuery = "Example"
    filters.pinnedDeviceIDs = [MainWindowTestFixtures.device.id]
    filters.pinnedAppIDs = [MainWindowTestFixtures.app.id]
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: oldSnapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded,
      filters: filters
    )

    state.applySnapshot(
      newSnapshot,
      refreshState: .idle,
      commandResults: []
    )

    #expect(state.filters == filters)
    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.device.id)
    #expect(state.deviceDetail.installedApps.selectedAppID == MainWindowTestFixtures.app.id)
  }

  @Test
  func refreshFailureKeepsExistingSnapshotAndFilters() {
    var filters = SimulatorFilters()
    filters.searchQuery = "DEVICE-1"
    filters.pinnedDeviceIDs = [MainWindowTestFixtures.device.id]
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      filters: filters
    )

    state.applyRefreshFailure(.failed(diagnostic: "simctl failed"), commandResults: [MainWindowTestFixtures.failedXcodeCommandResult])

    #expect(state.snapshot == snapshot)
    #expect(state.filters == filters)
    #expect(state.refreshState == .failed(diagnostic: "simctl failed"))
  }
}
