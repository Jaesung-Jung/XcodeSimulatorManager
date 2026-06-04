import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite
struct InstalledAppTests {
  @Test func preservesMetadataContainerPathsAndIconPath() {
    let appGroup = AppGroupContainer(
      id: "group.com.example",
      groupID: "group.com.example",
      path: URL(fileURLWithPath: "/tmp/Groups/group.com.example")
    )
    let app = InstalledApp(
      id: "device-1:com.example.app",
      bundleID: "com.example.app",
      displayName: "Example",
      version: "1.0",
      build: "100",
      deviceID: "device-1",
      bundleContainer: URL(fileURLWithPath: "/tmp/Bundle/Application/app"),
      dataContainer: URL(fileURLWithPath: "/tmp/Data/Application/app"),
      appBundlePath: URL(fileURLWithPath: "/tmp/Bundle/Application/app/App.app"),
      appGroups: [appGroup],
      iconPath: URL(fileURLWithPath: "/tmp/Bundle/Application/app/App.app/AppIcon.png"),
      isSystemApp: true,
      databaseFiles: [URL(fileURLWithPath: "/tmp/Data/Application/app/Documents/store.sqlite")],
      dataContainerSize: 256
    )

    #expect(app.id == "device-1:com.example.app")
    #expect(app.bundleID == "com.example.app")
    #expect(app.displayName == "Example")
    #expect(app.version == "1.0")
    #expect(app.build == "100")
    #expect(app.deviceID == "device-1")
    #expect(app.bundleContainer == URL(fileURLWithPath: "/tmp/Bundle/Application/app"))
    #expect(app.dataContainer == URL(fileURLWithPath: "/tmp/Data/Application/app"))
    #expect(app.appBundlePath == URL(fileURLWithPath: "/tmp/Bundle/Application/app/App.app"))
    #expect(app.appGroups == [appGroup])
    #expect(app.iconPath == URL(fileURLWithPath: "/tmp/Bundle/Application/app/App.app/AppIcon.png"))
    #expect(app.isSystemApp)
    #expect(app.databaseFiles == [URL(fileURLWithPath: "/tmp/Data/Application/app/Documents/store.sqlite")])
    #expect(app.dataContainerSize == 256)
  }

  @Test func supportsMissingOptionalMetadataAndPaths() {
    let app = InstalledApp(
      id: "device-1:com.example.partial",
      bundleID: "com.example.partial",
      displayName: "Partial",
      version: nil,
      build: nil,
      deviceID: "device-1",
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )

    #expect(app.version == nil)
    #expect(app.build == nil)
    #expect(app.bundleContainer == nil)
    #expect(app.dataContainer == nil)
    #expect(app.appBundlePath == nil)
    #expect(app.appGroups.isEmpty)
    #expect(app.iconPath == nil)
    #expect(app.isSystemApp == false)
    #expect(app.databaseFiles.isEmpty)
    #expect(app.dataContainerSize == nil)
  }
}
