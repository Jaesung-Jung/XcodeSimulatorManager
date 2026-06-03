// MARK: - DeveloperToolsFeature.LocationCoordinateInput

extension DeveloperToolsFeature {
  public struct LocationCoordinateInput: Equatable, Hashable, Identifiable {
    public let name: String
    public let latitude: String
    public let longitude: String

    public init(name: String, latitude: String, longitude: String) {
      self.name = name
      self.latitude = latitude
      self.longitude = longitude
    }

    public var id: String {
      "\(latitude),\(longitude)"
    }
  }
}

// MARK: - DeveloperToolsFeature.LocationPreset

extension DeveloperToolsFeature {
  public enum LocationPreset: String, CaseIterable, Equatable, Identifiable {
    case applePark
    case sanFrancisco
    case london
    case tokyo
    case seoul
    case custom

    public var id: String {
      rawValue
    }

    public var displayTitle: String {
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

    public var coordinate: LocationCoordinateInput? {
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
}
