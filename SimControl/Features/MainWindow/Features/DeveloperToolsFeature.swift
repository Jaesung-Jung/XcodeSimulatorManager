import ComposableArchitecture
import Foundation

@Reducer
struct DeveloperToolsFeature {
  struct LocationCoordinateInput: Equatable, Hashable, Identifiable {
    let name: String
    let latitude: String
    let longitude: String

    var id: String {
      "\(latitude),\(longitude)"
    }
  }

  enum LocationPreset: String, CaseIterable, Equatable, Identifiable {
    case applePark
    case sanFrancisco
    case london
    case tokyo
    case seoul
    case custom

    var id: String {
      rawValue
    }

    var displayTitle: String {
      switch self {
      case .applePark:
        "Apple Park"
      case .sanFrancisco:
        "San Francisco"
      case .london:
        "London"
      case .tokyo:
        "Tokyo"
      case .seoul:
        "Seoul"
      case .custom:
        "Custom"
      }
    }

    var coordinate: LocationCoordinateInput? {
      switch self {
      case .applePark:
        LocationCoordinateInput(
          name: displayTitle,
          latitude: "37.334900",
          longitude: "-122.009020"
        )
      case .sanFrancisco:
        LocationCoordinateInput(
          name: displayTitle,
          latitude: "37.774900",
          longitude: "-122.419400"
        )
      case .london:
        LocationCoordinateInput(
          name: displayTitle,
          latitude: "51.507400",
          longitude: "-0.127800"
        )
      case .tokyo:
        LocationCoordinateInput(
          name: displayTitle,
          latitude: "35.676200",
          longitude: "139.650300"
        )
      case .seoul:
        LocationCoordinateInput(
          name: displayTitle,
          latitude: "37.566500",
          longitude: "126.978000"
        )
      case .custom:
        nil
      }
    }
  }

  enum PrivacyAction: String, CaseIterable, Equatable, Identifiable {
    case grant
    case revoke
    case reset

    var id: String {
      rawValue
    }

    var displayTitle: String {
      switch self {
      case .grant:
        "Grant"
      case .revoke:
        "Revoke"
      case .reset:
        "Reset"
      }
    }

    var requiresBundleID: Bool {
      self == .grant || self == .revoke
    }
  }

  enum PrivacyService: String, CaseIterable, Equatable, Identifiable {
    case all
    case calendar
    case camera
    case contactsLimited
    case contacts
    case location
    case locationAlways
    case photosAdd
    case photos
    case mediaLibrary
    case microphone
    case motion
    case reminders
    case siri
    case notifications
    case bluetooth

    var id: String {
      rawValue
    }

    var displayTitle: String {
      switch self {
      case .all:
        "All"
      case .calendar:
        "Calendar"
      case .camera:
        "Camera"
      case .contactsLimited:
        "Contacts Limited"
      case .contacts:
        "Contacts"
      case .location:
        "Location When In Use"
      case .locationAlways:
        "Location Always"
      case .photosAdd:
        "Photos Add"
      case .photos:
        "Photos"
      case .mediaLibrary:
        "Media Library"
      case .microphone:
        "Microphone"
      case .motion:
        "Motion"
      case .reminders:
        "Reminders"
      case .siri:
        "Siri"
      case .notifications:
        "Notifications"
      case .bluetooth:
        "Bluetooth"
      }
    }

    var simctlArgument: String {
      switch self {
      case .all:
        "all"
      case .calendar:
        "calendar"
      case .camera:
        "camera"
      case .contactsLimited:
        "contacts-limited"
      case .contacts:
        "contacts"
      case .location:
        "location"
      case .locationAlways:
        "location-always"
      case .photosAdd:
        "photos-add"
      case .photos:
        "photos"
      case .mediaLibrary:
        "media-library"
      case .microphone:
        "microphone"
      case .motion:
        "motion"
      case .reminders:
        "reminders"
      case .siri:
        "siri"
      case .notifications:
        "notifications"
      case .bluetooth:
        "bluetooth"
      }
    }

    var unsupportedReason: String? {
      switch self {
      case .camera, .notifications, .bluetooth:
        "\(displayTitle) is not listed by this Xcode simctl privacy help."
      case .all,
           .calendar,
           .contactsLimited,
           .contacts,
           .location,
           .locationAlways,
           .photosAdd,
           .photos,
           .mediaLibrary,
           .microphone,
           .motion,
           .reminders,
           .siri:
        nil
      }
    }
  }

  @ObservableState
  struct State: Equatable {
    var device: SimulatorDevice?
    var installedApps: [InstalledApp]
    var selectedAppID: String?
    var deviceCommandState: DeviceCommandState?
    var appCommandState: AppCommandState?
    var deepLinkURLString: String
    var recentDeepLinkURLs: [String]
    var pushBundleID: String
    var pushPayloadJSON: String
    var privacyAction: PrivacyAction
    var privacyService: PrivacyService
    var privacyBundleID: String
    var locationPreset: LocationPreset
    var customLatitude: String
    var customLongitude: String
    var recentLocations: [LocationCoordinateInput]

    init(
      device: SimulatorDevice? = nil,
      installedApps: [InstalledApp] = [],
      selectedAppID: String? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      deepLinkURLString: String = "",
      recentDeepLinkURLs: [String] = [],
      pushBundleID: String = "",
      pushPayloadJSON: String = Self.defaultPushPayloadJSON,
      privacyAction: PrivacyAction = .grant,
      privacyService: PrivacyService = .location,
      privacyBundleID: String = "",
      locationPreset: LocationPreset = .applePark,
      customLatitude: String = "",
      customLongitude: String = "",
      recentLocations: [LocationCoordinateInput] = []
    ) {
      self.device = device
      self.installedApps = installedApps
      self.selectedAppID = selectedAppID
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState
      self.deepLinkURLString = deepLinkURLString
      self.recentDeepLinkURLs = recentDeepLinkURLs
      self.pushBundleID = pushBundleID
      self.pushPayloadJSON = pushPayloadJSON
      self.privacyAction = privacyAction
      self.privacyService = privacyService
      self.privacyBundleID = privacyBundleID
      self.locationPreset = locationPreset
      self.customLatitude = customLatitude
      self.customLongitude = customLongitude
      self.recentLocations = recentLocations
      applySelectedAppBundleIfNeeded()
    }

    var selectedApp: InstalledApp? {
      guard let selectedAppID else {
        return nil
      }

      return installedApps.first { $0.id == selectedAppID }
    }

    var selectedAppBundleID: String? {
      selectedApp?.bundleID
    }

    var appBundleIDOptions: [String] {
      Array(Set(installedApps.map(\.bundleID).filter { !$0.isEmpty }))
        .sorted()
    }

    var openDeepLinkDisabledReason: String? {
      runnableDeviceDisabledReason
        ?? Self.urlValidationError(deepLinkURLString)
    }

    var sendPushDisabledReason: String? {
      runnableDeviceDisabledReason
        ?? Self.pushPayloadValidationError(
          pushPayloadJSON,
          bundleID: pushBundleID
        )
    }

    var applyPrivacyDisabledReason: String? {
      if let runnableDeviceDisabledReason {
        return runnableDeviceDisabledReason
      }

      if let unsupportedReason = privacyService.unsupportedReason {
        return unsupportedReason
      }

      if privacyAction.requiresBundleID && Self.trimmed(privacyBundleID).isEmpty {
        return "Grant and revoke require a bundle identifier."
      }

      return nil
    }

    var setLocationDisabledReason: String? {
      runnableDeviceDisabledReason
        ?? selectedLocationValidationError
    }

    var clearLocationDisabledReason: String? {
      runnableDeviceDisabledReason
    }

    var selectedLocationCoordinate: LocationCoordinateInput? {
      switch locationPreset {
      case .custom:
        LocationCoordinateInput(
          name: "Custom",
          latitude: customLatitude,
          longitude: customLongitude
        )
      case .applePark,
           .sanFrancisco,
           .london,
           .tokyo,
           .seoul:
        locationPreset.coordinate
      }
    }

    private var selectedLocationValidationError: String? {
      guard let selectedLocationCoordinate else {
        return "Select a location preset."
      }

      return Self.coordinateValidationError(
        latitude: selectedLocationCoordinate.latitude,
        longitude: selectedLocationCoordinate.longitude
      )
    }

    private var runnableDeviceDisabledReason: String? {
      if deviceCommandState != nil {
        return "Another simulator command is running."
      }

      if appCommandState != nil {
        return "An app command is running."
      }

      guard let device else {
        return "Select a simulator."
      }

      guard device.isAvailable else {
        return "Selected simulator is unavailable."
      }

      guard device.state == .booted || device.state == .shutdown else {
        return "Selected simulator must be booted or shutdown."
      }

      return nil
    }

    mutating func updateContext(
      device: SimulatorDevice?,
      installedApps: [InstalledApp],
      selectedAppID: String?,
      deviceCommandState: DeviceCommandState?,
      appCommandState: AppCommandState?
    ) {
      let previousDeviceID = self.device?.id
      self.device = device
      self.installedApps = installedApps
      self.selectedAppID = selectedAppID
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState

      if previousDeviceID != device?.id {
        pushBundleID = selectedApp?.bundleID ?? ""
        privacyBundleID = selectedApp?.bundleID ?? ""
      } else {
        applySelectedAppBundleIfNeeded()
      }
    }

    mutating func recordDeepLinkURL(_ urlString: String) {
      let urlString = Self.trimmed(urlString)
      guard !urlString.isEmpty else {
        return
      }

      recentDeepLinkURLs.removeAll { $0 == urlString }
      recentDeepLinkURLs.insert(urlString, at: 0)
      recentDeepLinkURLs = Array(recentDeepLinkURLs.prefix(5))
    }

    mutating func recordLocation(_ location: LocationCoordinateInput) {
      guard Self.coordinateValidationError(
        latitude: location.latitude,
        longitude: location.longitude
      ) == nil else {
        return
      }

      recentLocations.removeAll { $0.id == location.id }
      recentLocations.insert(location, at: 0)
      recentLocations = Array(recentLocations.prefix(5))
    }

    mutating func applySelectedAppBundle() {
      guard let selectedAppBundleID else {
        return
      }

      pushBundleID = selectedAppBundleID
      privacyBundleID = selectedAppBundleID
    }

    private mutating func applySelectedAppBundleIfNeeded() {
      guard let selectedAppBundleID else {
        return
      }

      if Self.trimmed(pushBundleID).isEmpty {
        pushBundleID = selectedAppBundleID
      }

      if Self.trimmed(privacyBundleID).isEmpty {
        privacyBundleID = selectedAppBundleID
      }
    }

    static func urlValidationError(_ value: String) -> String? {
      let value = Self.trimmed(value)

      guard !value.isEmpty else {
        return "Enter a URL."
      }

      guard let components = URLComponents(string: value),
            let scheme = components.scheme,
            !scheme.isEmpty
      else {
        return "URL must include a scheme."
      }

      let allowedSchemeCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-."
      )
      guard scheme.rangeOfCharacter(from: allowedSchemeCharacters.inverted) == nil,
            scheme.first?.isLetter == true
      else {
        return "URL scheme is invalid."
      }

      return nil
    }

    static func pushPayloadValidationError(
      _ payloadJSON: String,
      bundleID: String
    ) -> String? {
      let payloadJSON = Self.trimmed(payloadJSON)

      guard !payloadJSON.isEmpty else {
        return "Enter a push payload."
      }

      let data = Data(payloadJSON.utf8)
      guard data.count <= 4_096 else {
        return "Push payload must be 4096 bytes or less."
      }

      let object: Any
      do {
        object = try JSONSerialization.jsonObject(with: data)
      } catch {
        return "Push payload must be valid JSON."
      }

      guard let payload = object as? [String: Any] else {
        return "Push payload must be a JSON object."
      }

      guard payload["aps"] is [String: Any] else {
        return "Push payload must contain an aps object."
      }

      if Self.trimmed(bundleID).isEmpty,
         Self.trimmed(payload["Simulator Target Bundle"] as? String ?? "").isEmpty {
        return "Select a bundle identifier or include Simulator Target Bundle."
      }

      return nil
    }

    static func coordinateValidationError(
      latitude: String,
      longitude: String
    ) -> String? {
      guard let latitude = Double(Self.trimmed(latitude)),
            let longitude = Double(Self.trimmed(longitude))
      else {
        return "Latitude and longitude must be numbers."
      }

      guard (-90...90).contains(latitude) else {
        return "Latitude must be between -90 and 90."
      }

      guard (-180...180).contains(longitude) else {
        return "Longitude must be between -180 and 180."
      }

      return nil
    }

    static func trimmed(_ value: String) -> String {
      value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let defaultPushPayloadJSON = """
    {
      "aps": {
        "alert": "Hello from SimControl"
      }
    }
    """
  }

  enum Action: Equatable {
    case deepLinkURLChanged(String)
    case recentDeepLinkURLSelected(String)
    case openDeepLinkButtonTapped
    case pushBundleIDChanged(String)
    case pushPayloadJSONChanged(String)
    case sendPushButtonTapped
    case privacyActionChanged(PrivacyAction)
    case privacyServiceChanged(PrivacyService)
    case privacyBundleIDChanged(String)
    case useSelectedAppBundleButtonTapped
    case applyPrivacyButtonTapped
    case locationPresetChanged(LocationPreset)
    case customLatitudeChanged(String)
    case customLongitudeChanged(String)
    case recentLocationSelected(LocationCoordinateInput)
    case setLocationButtonTapped
    case clearLocationButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .deepLinkURLChanged(let urlString):
        state.deepLinkURLString = urlString
        return .none

      case .recentDeepLinkURLSelected(let urlString):
        state.deepLinkURLString = urlString
        return .none

      case .pushBundleIDChanged(let bundleID):
        state.pushBundleID = bundleID
        return .none

      case .pushPayloadJSONChanged(let payloadJSON):
        state.pushPayloadJSON = payloadJSON
        return .none

      case .privacyActionChanged(let privacyAction):
        state.privacyAction = privacyAction
        return .none

      case .privacyServiceChanged(let privacyService):
        state.privacyService = privacyService
        return .none

      case .privacyBundleIDChanged(let bundleID):
        state.privacyBundleID = bundleID
        return .none

      case .useSelectedAppBundleButtonTapped:
        state.applySelectedAppBundle()
        return .none

      case .locationPresetChanged(let locationPreset):
        state.locationPreset = locationPreset
        return .none

      case .customLatitudeChanged(let latitude):
        state.customLatitude = latitude
        return .none

      case .customLongitudeChanged(let longitude):
        state.customLongitude = longitude
        return .none

      case .recentLocationSelected(let location):
        state.locationPreset = .custom
        state.customLatitude = location.latitude
        state.customLongitude = location.longitude
        return .none

      case .openDeepLinkButtonTapped,
           .sendPushButtonTapped,
           .applyPrivacyButtonTapped,
           .setLocationButtonTapped,
           .clearLocationButtonTapped:
        return .none
      }
    }
  }
}
