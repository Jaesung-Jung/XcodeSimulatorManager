import Foundation
import Testing
@testable import SimControl

@Suite
struct SimctlListPayloadTests {
  @Test func decodesRepresentativeListPayload() throws {
    let payload = try decode(
      """
      {
        "runtimes": [
          {
            "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
            "name": "iOS 26.4",
            "version": "26.4",
            "buildversion": "23E244",
            "platform": "iOS",
            "isAvailable": true,
            "supportedDeviceTypes": [
              {
                "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                "name": "iPhone 17 Pro",
                "productFamily": "iPhone",
                "futureField": "ignored"
              }
            ],
            "futureRuntimeField": "ignored"
          }
        ],
        "devicetypes": [
          {
            "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "name": "iPhone 17 Pro",
            "productFamily": "iPhone",
            "modelIdentifier": "iPhone18,1",
            "futureDeviceTypeField": "ignored"
          }
        ],
        "devices": {
          "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
            {
              "udid": "PHONE-UDID",
              "name": "iPhone 17 Pro",
              "state": "Shutdown",
              "isAvailable": true,
              "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
              "dataPath": "/Users/example/Library/Developer/CoreSimulator/Devices/PHONE-UDID/data",
              "logPath": "/Users/example/Library/Logs/CoreSimulator/PHONE-UDID",
              "lastBootedAt": "2026-04-28T10:28:10Z",
              "dataPathSize": 15844028416,
              "futureDeviceField": "ignored"
            }
          ]
        },
        "pairs": {
          "PAIR-1": {
            "state": "active",
            "phone": {
              "udid": "PHONE-UDID",
              "name": "iPhone 17 Pro",
              "state": "Booted"
            },
            "watch": {
              "udid": "WATCH-UDID",
              "name": "Apple Watch Series 10",
              "state": "Shutdown"
            },
            "futurePairField": "ignored"
          }
        },
        "futureTopLevelField": "ignored"
      }
      """
    )

    let runtime = try #require(payload.runtimes.first)
    #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-4")
    #expect(runtime.name == "iOS 26.4")
    #expect(runtime.version == "26.4")
    #expect(runtime.buildVersion == "23E244")
    #expect(runtime.platform == "iOS")
    #expect(runtime.isAvailable == true)
    #expect(runtime.supportedDeviceTypes.first?.identifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")

    let deviceType = try #require(payload.deviceTypes.first)
    #expect(deviceType.identifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
    #expect(deviceType.name == "iPhone 17 Pro")
    #expect(deviceType.productFamily == "iPhone")
    #expect(deviceType.modelIdentifier == "iPhone18,1")

    let devices = try #require(payload.devicesByRuntimeID["com.apple.CoreSimulator.SimRuntime.iOS-26-4"])
    let device = try #require(devices.first)
    #expect(device.udid == "PHONE-UDID")
    #expect(device.name == "iPhone 17 Pro")
    #expect(device.state == "Shutdown")
    #expect(device.isAvailable == true)
    #expect(device.deviceTypeIdentifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
    #expect(device.dataPath == "/Users/example/Library/Developer/CoreSimulator/Devices/PHONE-UDID/data")
    #expect(device.logPath == "/Users/example/Library/Logs/CoreSimulator/PHONE-UDID")
    #expect(device.lastBootedAt == "2026-04-28T10:28:10Z")
    #expect(device.dataPathSize == 15_844_028_416)

    let pair = try #require(payload.pairsByID["PAIR-1"])
    #expect(pair.state == "active")
    #expect(pair.phone?.udid == "PHONE-UDID")
    #expect(pair.watch?.udid == "WATCH-UDID")
  }

  @Test func missingTopLevelCollectionsDefaultToEmpty() throws {
    let payload = try decode("{}")

    #expect(payload.runtimes.isEmpty)
    #expect(payload.deviceTypes.isEmpty)
    #expect(payload.devicesByRuntimeID.isEmpty)
    #expect(payload.pairsByID.isEmpty)
  }

  @Test func missingOptionalFieldsDoNotFailTheWholeDecode() throws {
    let payload = try decode(
      """
      {
        "runtimes": [{}],
        "devicetypes": [{}],
        "devices": {
          "runtime-with-partial-device": [{}]
        },
        "pairs": {
          "PAIR-WITH-PARTIAL-FIELDS": {}
        }
      }
      """
    )

    let runtime = try #require(payload.runtimes.first)
    #expect(runtime.identifier == nil)
    #expect(runtime.name == nil)
    #expect(runtime.supportedDeviceTypes.isEmpty)

    let deviceType = try #require(payload.deviceTypes.first)
    #expect(deviceType.identifier == nil)
    #expect(deviceType.modelIdentifier == nil)

    let devices = try #require(payload.devicesByRuntimeID["runtime-with-partial-device"])
    let device = try #require(devices.first)
    #expect(device.udid == nil)
    #expect(device.dataPath == nil)
    #expect(device.dataPathSize == nil)

    let pair = try #require(payload.pairsByID["PAIR-WITH-PARTIAL-FIELDS"])
    #expect(pair.state == nil)
    #expect(pair.phone == nil)
    #expect(pair.watch == nil)
  }

  private func decode(_ json: String) throws -> SimctlListPayload {
    try JSONDecoder().decode(SimctlListPayload.self, from: Data(json.utf8))
  }
}
