// MARK: - DeveloperToolsFeature.State Location

extension DeveloperToolsFeature.State {
  public var setLocationDisabledReason: String? {
    runnableDeviceDisabledReason
      ?? selectedLocationValidationError
  }

  public var selectedLocationCoordinate: DeveloperToolsFeature.LocationCoordinateInput? {
    switch locationPreset {
    case .custom:
      DeveloperToolsFeature.LocationCoordinateInput(
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
}
