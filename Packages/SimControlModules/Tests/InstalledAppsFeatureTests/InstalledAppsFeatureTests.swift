import AppKit
import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import SimControlDomain
import Testing
@testable import InstalledAppsFeature

@Suite
@MainActor
struct InstalledAppsFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let app = InstalledApp(
      id: "app-1",
      bundleID: "com.example.app",
      displayName: "Example",
      version: nil,
      build: nil,
      deviceID: "device-1",
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )

    let state = InstalledAppsFeature.State(
      apps: [app],
      availability: .loaded,
      selectedAppID: app.id,
      allAppsCount: 1
    )

    #expect(state.apps.map(\.id) == [app.id])
    #expect(state.availability == .loaded)
    #expect(state.selectedAppID == app.id)
    #expect(state.selectedApp?.id == app.id)
  }

  @Test func selectionChangedStoresSelectedAppID() async {
    let store = TestStore(initialState: InstalledAppsFeature.State()) {
      InstalledAppsFeature()
    }

    await store.send(.selectionChanged("app-1")) {
      $0.selectedAppID = "app-1"
    }
  }

  @Test func showHiddenSystemAppsChangedUpdatesFilters() async {
    let store = TestStore(initialState: InstalledAppsFeature.State()) {
      InstalledAppsFeature()
    }

    await store.send(.showHiddenSystemAppsChanged(true)) {
      $0.filters.showsHiddenSystemApps = true
    }
  }

  @Test func stateGroupsUserAndSystemApps() {
    let userApp = InstalledApp(
      id: "app-1",
      bundleID: "com.example.app",
      displayName: "Example",
      version: nil,
      build: nil,
      deviceID: "device-1",
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )
    let systemApp = InstalledApp(
      id: "app-2",
      bundleID: "com.apple.Preferences",
      displayName: "Settings",
      version: nil,
      build: nil,
      deviceID: "device-1",
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil,
      isSystemApp: true
    )
    let state = InstalledAppsFeature.State(
      apps: [systemApp, userApp],
      availability: .loaded
    )

    #expect(state.userApps.map(\.id) == [userApp.id])
    #expect(state.systemApps.map(\.id) == [systemApp.id])
  }

  @Test func appIconViewCanBeConstructedForRealAndFallbackIcons() {
    _ = InstalledAppsView.AppIconView(iconPath: URL(fileURLWithPath: "/tmp/AppIcon.png"))
    _ = InstalledAppsView.AppIconView(iconPath: nil)
  }

  @Test func appIconImageLoaderCachesLoadedImages() async {
    let url = URL(fileURLWithPath: "/tmp/AppIcon.png")
    let probe = AppIconImageLoadProbe()
    let loader = AppIconImageLoader { url in
      await probe.loadImage(url)
    }

    let firstImage = await loader.image(for: url)
    let secondImage = await loader.image(for: url)
    let expectedImage = await probe.image()

    #expect(firstImage === expectedImage)
    #expect(secondImage === expectedImage)
    #expect(await probe.loadCount() == 1)
  }
}

private actor AppIconImageLoadProbe {
  private let loadedImage = NSImage(size: NSSize(width: 2, height: 2))
  private var loads = 0

  func image() -> NSImage {
    loadedImage
  }

  func loadImage(_: URL) -> NSImage? {
    loads += 1
    return loadedImage
  }

  func loadCount() -> Int {
    loads
  }
}
