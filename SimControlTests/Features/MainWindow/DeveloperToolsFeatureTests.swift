import ComposableArchitecture
import Testing

@testable import SimControl

@MainActor
struct DeveloperToolsFeatureTests {
  @Test
  func deepLinkValidationRequiresSchemeAndRunnableDevice() {
    let validState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted),
      deepLinkURLString: "myapp://home"
    )
    let invalidURLState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted),
      deepLinkURLString: "example.com"
    )
    let unavailableState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", isAvailable: false),
      deepLinkURLString: "myapp://home"
    )

    #expect(validState.openDeepLinkDisabledReason == nil)
    #expect(invalidURLState.openDeepLinkDisabledReason == "URL must include a scheme.")
    #expect(unavailableState.openDeepLinkDisabledReason == "Selected simulator is unavailable.")
  }

  @Test
  func pushPayloadValidationRequiresJSONObjectApsAndBundleTarget() {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let validState = DeveloperToolsFeature.State(
      device: device,
      pushBundleID: "com.example.app",
      pushPayloadJSON: #"{"aps":{"alert":"Hello"}}"#
    )
    let missingApsState = DeveloperToolsFeature.State(
      device: device,
      pushBundleID: "com.example.app",
      pushPayloadJSON: #"{"alert":"Hello"}"#
    )
    let missingBundleState = DeveloperToolsFeature.State(
      device: device,
      pushBundleID: "",
      pushPayloadJSON: #"{"aps":{"alert":"Hello"}}"#
    )
    let payloadTargetState = DeveloperToolsFeature.State(
      device: device,
      pushBundleID: "",
      pushPayloadJSON: #"{"Simulator Target Bundle":"com.example.app","aps":{"alert":"Hello"}}"#
    )

    #expect(validState.sendPushDisabledReason == nil)
    #expect(missingApsState.sendPushDisabledReason == "Push payload must contain an aps object.")
    #expect(
      missingBundleState.sendPushDisabledReason
        == "Select a bundle identifier or include Simulator Target Bundle."
    )
    #expect(payloadTargetState.sendPushDisabledReason == nil)
  }

  @Test
  func privacyValidationDisablesUnsupportedServicesAndRequiresBundleForGrant() {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let validResetState = DeveloperToolsFeature.State(
      device: device,
      privacyAction: .reset,
      privacyService: .all,
      privacyBundleID: ""
    )
    let missingBundleState = DeveloperToolsFeature.State(
      device: device,
      privacyAction: .grant,
      privacyService: .location,
      privacyBundleID: ""
    )
    let unsupportedState = DeveloperToolsFeature.State(
      device: device,
      privacyAction: .grant,
      privacyService: .camera,
      privacyBundleID: "com.example.app"
    )

    #expect(validResetState.applyPrivacyDisabledReason == nil)
    #expect(
      missingBundleState.applyPrivacyDisabledReason
        == "Grant and revoke require a bundle identifier."
    )
    #expect(
      unsupportedState.applyPrivacyDisabledReason
        == "Camera is not listed by this Xcode simctl privacy help."
    )
  }

  @Test
  func locationValidationRejectsInvalidCoordinates() {
    let validState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted),
      locationPreset: .custom,
      customLatitude: "37.3349",
      customLongitude: "-122.0090"
    )
    let invalidLatitudeState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted),
      locationPreset: .custom,
      customLatitude: "91",
      customLongitude: "0"
    )
    let invalidLongitudeState = DeveloperToolsFeature.State(
      device: MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted),
      locationPreset: .custom,
      customLatitude: "0",
      customLongitude: "181"
    )

    #expect(validState.setLocationDisabledReason == nil)
    #expect(invalidLatitudeState.setLocationDisabledReason == "Latitude must be between -90 and 90.")
    #expect(invalidLongitudeState.setLocationDisabledReason == "Longitude must be between -180 and 180.")
  }

  @Test
  func selectedAppBundleCanFillPushAndPrivacyTargets() async {
    let store = TestStore(
      initialState: DeveloperToolsFeature.State(
        device: MainWindowTestFixtures.device,
        installedApps: [MainWindowTestFixtures.app],
        selectedAppID: MainWindowTestFixtures.app.id,
        pushBundleID: "manual.push",
        privacyBundleID: "manual.privacy"
      )
    ) {
      DeveloperToolsFeature()
    }

    await store.send(.useSelectedAppBundleButtonTapped) {
      $0.pushBundleID = MainWindowTestFixtures.app.bundleID
      $0.privacyBundleID = MainWindowTestFixtures.app.bundleID
    }
  }
}
