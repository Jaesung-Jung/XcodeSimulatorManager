import Foundation

// MARK: - DeveloperToolsFeature.State Validation

extension DeveloperToolsFeature.State {
  public mutating func recordDeepLinkURL(_ urlString: String) {
    let urlString = Self.trimmed(urlString)
    guard !urlString.isEmpty else {
      return
    }

    recentDeepLinkURLs.removeAll { $0 == urlString }
    recentDeepLinkURLs.insert(urlString, at: 0)
    recentDeepLinkURLs = Array(recentDeepLinkURLs.prefix(5))
  }

  public mutating func recordLocation(_ location: DeveloperToolsFeature.LocationCoordinateInput) {
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

  public static func urlValidationError(_ value: String) -> String? {
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

  public static func pushPayloadValidationError(
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

  public static func coordinateValidationError(
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

  public static func integerValidationError(
    _ value: String,
    label: String,
    range: ClosedRange<Int>
  ) -> String? {
    let value = Self.trimmed(value)
    guard !value.isEmpty else {
      return nil
    }

    guard let integer = Int(value) else {
      return "\(label) must be a whole number."
    }

    guard range.contains(integer) else {
      return "\(label) must be between \(range.lowerBound) and \(range.upperBound)."
    }

    return nil
  }

  public static func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public static let defaultPushPayloadJSON = """
  {
    "aps": {
      "alert": "Hello from SimControl"
    }
  }
  """
}
