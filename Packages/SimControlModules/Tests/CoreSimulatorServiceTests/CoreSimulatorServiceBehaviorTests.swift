import Foundation
import SimControlDomain
import Testing
@testable import CoreSimulatorService

@Suite("CoreSimulatorServiceTests")
struct CoreSimulatorServiceTests {
  @Test func selectedXcodePathRunsXcodeSelectCommandAndTrimsOutput() async {
    let commandResult = makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stdout: "/Applications/Xcode.app/Contents/Developer\n"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.selectedXcodePath()

    #expect(result.succeeded)
    #expect(result.developerPath == URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"))
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == nil)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcode-select",
        arguments: ["-p"],
        timeout: 10
      )
    ])
  }

  @Test func selectedXcodePathFailurePreservesCommandResult() async {
    let commandResult = makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stderr: "xcode-select failed",
      exitCode: 72
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.selectedXcodePath()

    #expect(!result.succeeded)
    #expect(result.developerPath == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == "xcode-select -p failed with exit code 72.\nxcode-select failed")
  }

  @Test func listRunsSimctlListCommandAndDecodesPayload() async throws {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: """
      {
        "runtimes": [
          {
            "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
            "name": "iOS 26.4",
            "version": "26.4",
            "buildversion": "23E244",
            "platform": "iOS",
            "isAvailable": true
          }
        ],
        "devicetypes": [],
        "devices": {},
        "pairs": {}
      }
      """
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(result.succeeded)
    let payload = try #require(result.payload)
    #expect(payload.runtimes.first?.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-4")
    #expect(payload.deviceTypes.isEmpty)
    #expect(payload.devicesByRuntimeID.isEmpty)
    #expect(payload.pairsByID.isEmpty)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == nil)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "list", "-j"],
        timeout: 30
      )
    ])
  }

  @Test func listFailureDoesNotDecodeAndPreservesCommandResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "not json",
      stderr: "simctl failed",
      exitCode: 65
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(!result.succeeded)
    #expect(result.payload == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == "xcrun simctl list -j failed with exit code 65.\nsimctl failed")
  }

  @Test func listInvalidJSONPreservesSuccessfulCommandResultAndDiagnostic() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "not json"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(!result.succeeded)
    #expect(result.payload == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic?.contains("Failed to decode simctl list JSON") == true)
  }

  @Test func openSimulatorAppRunsOpenCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "open",
      arguments: ["-a", "Simulator"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.openSimulatorApp()

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "open",
        arguments: ["-a", "Simulator"],
        timeout: 10
      )
    ])
  }

  @Test func bootDeviceRunsSimctlBootCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "boot", "DEVICE-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.bootDevice(id: "DEVICE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "boot", "DEVICE-1"],
        timeout: 60
      )
    ])
  }

  @Test func shutdownDeviceRunsSimctlShutdownCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "shutdown", "DEVICE-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.shutdownDevice(id: "DEVICE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "shutdown", "DEVICE-1"],
        timeout: 60
      )
    ])
  }

  @Test func createDeviceRunsSimctlCreateCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: [
        "simctl",
        "create",
        "iPhone 17 Pro",
        "device-type-iphone",
        "runtime-ios"
      ],
      stdout: "CREATED-DEVICE\n"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.createDevice(
      name: "iPhone 17 Pro",
      deviceTypeID: "device-type-iphone",
      runtimeID: "runtime-ios"
    )

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: [
          "simctl",
          "create",
          "iPhone 17 Pro",
          "device-type-iphone",
          "runtime-ios"
        ],
        timeout: 60
      )
    ])
  }

  @Test func cloneDeviceRunsSimctlCloneCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "clone", "DEVICE-1", "Device Copy"],
      stdout: "CLONED-DEVICE\n"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.cloneDevice(id: "DEVICE-1", name: "Device Copy")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "clone", "DEVICE-1", "Device Copy"],
        timeout: 60
      )
    ])
  }

  @Test func renameDeviceRunsSimctlRenameCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "rename", "DEVICE-1", "Renamed Device"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.renameDevice(id: "DEVICE-1", name: "Renamed Device")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "rename", "DEVICE-1", "Renamed Device"],
        timeout: 60
      )
    ])
  }

  @Test func eraseDeviceRunsSimctlEraseCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "erase", "DEVICE-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.eraseDevice(id: "DEVICE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "erase", "DEVICE-1"],
        timeout: 60
      )
    ])
  }

  @Test func deleteDeviceRunsSimctlDeleteCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "delete", "DEVICE-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.deleteDevice(id: "DEVICE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "delete", "DEVICE-1"],
        timeout: 60
      )
    ])
  }

  @Test func pairDevicesRunsSimctlPairCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "pair", "WATCH-1", "PHONE-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.pairDevices(watchDeviceID: "WATCH-1", phoneDeviceID: "PHONE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "pair", "WATCH-1", "PHONE-1"],
        timeout: 60
      )
    ])
  }

  @Test func unpairDeviceRunsSimctlUnpairCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "unpair", "PAIR-1"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.unpairDevice(pairID: "PAIR-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "unpair", "PAIR-1"],
        timeout: 60
      )
    ])
  }

  @Test func bootDeviceIfNeededRunsSimctlBootstatusCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "bootstatus", "DEVICE-1", "-b"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.bootDeviceIfNeeded(id: "DEVICE-1")

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "bootstatus", "DEVICE-1", "-b"],
        timeout: 60
      )
    ])
  }

  @Test func appCommandsRunExpectedSimctlCommandsAndReturnResults() async {
    let appBundlePath = URL(fileURLWithPath: "/tmp/Example.app")
    let results = [
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "launch", "DEVICE-1", "com.example.app"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "terminate", "DEVICE-1", "com.example.app"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "uninstall", "DEVICE-1", "com.example.app"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "install", "DEVICE-2", appBundlePath.path]
      )
    ]
    let recorder = CommandRecorder(results: results)
    let service = makeService(recorder: recorder)

    let launchResult = await service.launchApp(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app"
    )
    let terminateResult = await service.terminateApp(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app"
    )
    let uninstallResult = await service.uninstallApp(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app"
    )
    let installResult = await service.installApp(
      deviceID: "DEVICE-2",
      appBundlePath: appBundlePath
    )

    #expect([launchResult, terminateResult, uninstallResult, installResult] == results)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "launch", "DEVICE-1", "com.example.app"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "terminate", "DEVICE-1", "com.example.app"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "uninstall", "DEVICE-1", "com.example.app"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "install", "DEVICE-2", appBundlePath.path],
        timeout: 60
      )
    ])
  }

  @Test func getAppContainerRunsExpectedSimctlCommandsAndReturnResults() async {
    let results = [
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "app"],
        stdout: "/tmp/Bundle/Example.app\n"
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "data"],
        stdout: "/tmp/Data\n"
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: [
          "simctl",
          "get_app_container",
          "DEVICE-1",
          "com.example.app",
          "group.com.example.shared"
        ],
        stdout: "/tmp/Group\n"
      )
    ]
    let recorder = CommandRecorder(results: results)
    let service = makeService(recorder: recorder)

    let appResult = await service.getAppContainer(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      container: .app
    )
    let dataResult = await service.getAppContainer(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      container: .data
    )
    let appGroupResult = await service.getAppContainer(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      container: .appGroup("group.com.example.shared")
    )

    #expect([appResult, dataResult, appGroupResult] == results)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "app"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "data"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: [
          "simctl",
          "get_app_container",
          "DEVICE-1",
          "com.example.app",
          "group.com.example.shared"
        ],
        timeout: 60
      )
    ])
  }

  @Test func developerToolCommandsRunExpectedSimctlCommandsAndReturnResults() async {
    let payloadURL = URL(fileURLWithPath: "/tmp/SimControlTests-RemoteNotificationPayload.json")
    let payloadJSON = #"{"aps":{"alert":"Hello"}}"#
    let statusBarArguments = ["--time", "09:41", "--batteryLevel", "100"]
    let results = [
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "openurl", "DEVICE-1", "myapp://home"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: [
          "simctl",
          "push",
          "DEVICE-1",
          "com.example.app",
          payloadURL.path
        ]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "privacy", "DEVICE-1", "grant", "location", "com.example.app"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "set", "37.334900,-122.009020"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "clear"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "override"] + statusBarArguments
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "clear"]
      )
    ]
    let recorder = CommandRecorder(results: results)
    let service = CoreSimulatorService(
      makeRemoteNotificationPayloadURL: { payloadURL },
      runCommand: { executable, arguments, timeout in
        await recorder.run(executable, arguments, timeout)
      }
    )

    let openResult = await service.openURL(
      deviceID: "DEVICE-1",
      urlString: "myapp://home"
    )
    let pushResult = await service.pushNotification(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      payloadJSON: payloadJSON
    )
    let privacyResult = await service.setPrivacyPermission(
      deviceID: "DEVICE-1",
      action: "grant",
      service: "location",
      bundleID: "com.example.app"
    )
    let setLocationResult = await service.setLocation(
      deviceID: "DEVICE-1",
      coordinate: "37.334900,-122.009020"
    )
    let clearLocationResult = await service.clearLocation(deviceID: "DEVICE-1")
    let statusBarResult = await service.setStatusBarOverride(
      deviceID: "DEVICE-1",
      arguments: statusBarArguments
    )
    let clearStatusBarResult = await service.clearStatusBarOverride(deviceID: "DEVICE-1")

    #expect(
      [
        openResult,
        pushResult,
        privacyResult,
        setLocationResult,
        clearLocationResult,
        statusBarResult,
        clearStatusBarResult
      ] == results
    )
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "openurl", "DEVICE-1", "myapp://home"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: [
          "simctl",
          "push",
          "DEVICE-1",
          "com.example.app",
          payloadURL.path
        ],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "privacy", "DEVICE-1", "grant", "location", "com.example.app"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "set", "37.334900,-122.009020"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "clear"],
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "override"] + statusBarArguments,
        timeout: 60
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "clear"],
        timeout: 60
      )
    ])
  }

  @Test func customTimeoutsAreForwardedToCommands() async {
    let payloadURL = URL(fileURLWithPath: "/tmp/SimControlTests-RemoteNotificationPayload.json")
    let recorder = CommandRecorder(results: [
      makeCommandResult(executable: "xcode-select", arguments: ["-p"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "list", "-j"]),
      makeCommandResult(executable: "open", arguments: ["-a", "Simulator"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "boot", "DEVICE-1"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "bootstatus", "DEVICE-1", "-b"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "shutdown", "DEVICE-1"]),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "create", "iPhone 17 Pro", "device-type-iphone", "runtime-ios"]
      ),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "clone", "DEVICE-1", "Device Copy"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "rename", "DEVICE-1", "Renamed Device"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "erase", "DEVICE-1"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "delete", "DEVICE-1"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "pair", "WATCH-1", "PHONE-1"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "unpair", "PAIR-1"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "launch", "DEVICE-1", "com.example.app"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "terminate", "DEVICE-1", "com.example.app"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "uninstall", "DEVICE-1", "com.example.app"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "install", "DEVICE-1", "/tmp/Example.app"]),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "data"]
      ),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "openurl", "DEVICE-1", "myapp://home"]),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "push", "DEVICE-1", "com.example.app", payloadURL.path]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "privacy", "DEVICE-1", "reset", "all"]
      ),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "set", "37.334900,-122.009020"]
      ),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "location", "DEVICE-1", "clear"]),
      makeCommandResult(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "override", "--time", "09:41"]
      ),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "status_bar", "DEVICE-1", "clear"])
    ])
    let service = makeService(
      recorder: recorder,
      selectedXcodePathTimeout: 1,
      listTimeout: 2,
      openSimulatorAppTimeout: 3,
      deviceCommandTimeout: 4,
      makeRemoteNotificationPayloadURL: { payloadURL }
    )

    _ = await service.selectedXcodePath()
    _ = await service.list()
    _ = await service.openSimulatorApp()
    _ = await service.bootDevice(id: "DEVICE-1")
    _ = await service.bootDeviceIfNeeded(id: "DEVICE-1")
    _ = await service.shutdownDevice(id: "DEVICE-1")
    _ = await service.createDevice(
      name: "iPhone 17 Pro",
      deviceTypeID: "device-type-iphone",
      runtimeID: "runtime-ios"
    )
    _ = await service.cloneDevice(id: "DEVICE-1", name: "Device Copy")
    _ = await service.renameDevice(id: "DEVICE-1", name: "Renamed Device")
    _ = await service.eraseDevice(id: "DEVICE-1")
    _ = await service.deleteDevice(id: "DEVICE-1")
    _ = await service.pairDevices(watchDeviceID: "WATCH-1", phoneDeviceID: "PHONE-1")
    _ = await service.unpairDevice(pairID: "PAIR-1")
    _ = await service.launchApp(deviceID: "DEVICE-1", bundleID: "com.example.app")
    _ = await service.terminateApp(deviceID: "DEVICE-1", bundleID: "com.example.app")
    _ = await service.uninstallApp(deviceID: "DEVICE-1", bundleID: "com.example.app")
    _ = await service.installApp(
      deviceID: "DEVICE-1",
      appBundlePath: URL(fileURLWithPath: "/tmp/Example.app")
    )
    _ = await service.getAppContainer(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      container: .data
    )
    _ = await service.openURL(deviceID: "DEVICE-1", urlString: "myapp://home")
    _ = await service.pushNotification(
      deviceID: "DEVICE-1",
      bundleID: "com.example.app",
      payloadJSON: #"{"aps":{"alert":"Hello"}}"#
    )
    _ = await service.setPrivacyPermission(
      deviceID: "DEVICE-1",
      action: "reset",
      service: "all",
      bundleID: nil
    )
    _ = await service.setLocation(
      deviceID: "DEVICE-1",
      coordinate: "37.334900,-122.009020"
    )
    _ = await service.clearLocation(deviceID: "DEVICE-1")
    _ = await service.setStatusBarOverride(
      deviceID: "DEVICE-1",
      arguments: ["--time", "09:41"]
    )
    _ = await service.clearStatusBarOverride(deviceID: "DEVICE-1")

    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcode-select",
        arguments: ["-p"],
        timeout: 1
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "list", "-j"],
        timeout: 2
      ),
      CommandCall(
        executable: "open",
        arguments: ["-a", "Simulator"],
        timeout: 3
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "boot", "DEVICE-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "bootstatus", "DEVICE-1", "-b"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "shutdown", "DEVICE-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "create", "iPhone 17 Pro", "device-type-iphone", "runtime-ios"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "clone", "DEVICE-1", "Device Copy"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "rename", "DEVICE-1", "Renamed Device"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "erase", "DEVICE-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "delete", "DEVICE-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "pair", "WATCH-1", "PHONE-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "unpair", "PAIR-1"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "launch", "DEVICE-1", "com.example.app"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "terminate", "DEVICE-1", "com.example.app"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "uninstall", "DEVICE-1", "com.example.app"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "install", "DEVICE-1", "/tmp/Example.app"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "get_app_container", "DEVICE-1", "com.example.app", "data"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "openurl", "DEVICE-1", "myapp://home"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "push", "DEVICE-1", "com.example.app", payloadURL.path],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "privacy", "DEVICE-1", "reset", "all"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "set", "37.334900,-122.009020"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "location", "DEVICE-1", "clear"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "override", "--time", "09:41"],
        timeout: 4
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "status_bar", "DEVICE-1", "clear"],
        timeout: 4
      )
    ])
  }

  private func makeService(recorder: CommandRecorder) -> CoreSimulatorService {
    CoreSimulatorService { executable, arguments, timeout in
      await recorder.run(executable, arguments, timeout)
    }
  }

  private func makeService(
    recorder: CommandRecorder,
    selectedXcodePathTimeout: TimeInterval?,
    listTimeout: TimeInterval?,
    openSimulatorAppTimeout: TimeInterval?,
    deviceCommandTimeout: TimeInterval?,
    makeRemoteNotificationPayloadURL: @escaping () -> URL = {
      URL(fileURLWithPath: "/tmp/SimControlTests-RemoteNotificationPayload.json")
    }
  ) -> CoreSimulatorService {
    CoreSimulatorService(
      selectedXcodePathTimeout: selectedXcodePathTimeout,
      listTimeout: listTimeout,
      openSimulatorAppTimeout: openSimulatorAppTimeout,
      deviceCommandTimeout: deviceCommandTimeout,
      makeRemoteNotificationPayloadURL: makeRemoteNotificationPayloadURL
    ) { executable, arguments, timeout in
      await recorder.run(executable, arguments, timeout)
    }
  }

  private func makeCommandResult(
    executable: String,
    arguments: [String],
    stdout: String = "",
    stderr: String = "",
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: "\(executable)-fixture",
      executable: executable,
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }
}

extension CoreSimulatorServiceTests {
  private struct CommandCall: Equatable {
    let executable: String
    let arguments: [String]
    let timeout: TimeInterval?
  }

  private actor CommandRecorder {
    private var results: [CommandResult]
    private var calls: [CommandCall] = []

    init(results: [CommandResult]) {
      self.results = results
    }

    func run(
      _ executable: String,
      _ arguments: [String],
      _ timeout: TimeInterval?
    ) -> CommandResult {
      calls.append(
        CommandCall(
          executable: executable,
          arguments: arguments,
          timeout: timeout
        )
      )

      guard !results.isEmpty else {
        return CommandResult(
          id: "missing-command-result",
          executable: executable,
          arguments: arguments,
          stdout: "",
          stderr: "No test command result was provided.",
          exitCode: -1,
          duration: 0,
          startedAt: Date(timeIntervalSince1970: 100)
        )
      }

      return results.removeFirst()
    }

    func recordedCalls() -> [CommandCall] {
      calls
    }
  }
}
