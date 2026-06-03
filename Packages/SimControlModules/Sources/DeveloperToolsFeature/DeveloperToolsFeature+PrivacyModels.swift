// MARK: - DeveloperToolsFeature.PrivacyAction

extension DeveloperToolsFeature {
  public enum PrivacyAction: String, CaseIterable, Equatable, Identifiable {
    case grant
    case revoke
    case reset

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
      switch self {
      case .grant:
        "Grant"
      case .revoke:
        "Revoke"
      case .reset:
        "Reset"
      }
    }

    public var requiresBundleID: Bool {
      self == .grant || self == .revoke
    }
  }
}

// MARK: - DeveloperToolsFeature.PrivacyService

extension DeveloperToolsFeature {
  public enum PrivacyService: String, CaseIterable, Equatable, Identifiable {
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

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
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

    public var simctlArgument: String {
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

    public var unsupportedReason: String? {
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
}
