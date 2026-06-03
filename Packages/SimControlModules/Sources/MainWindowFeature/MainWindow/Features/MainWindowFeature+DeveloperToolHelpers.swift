import DeveloperToolsFeature
import Foundation

// MARK: - MainWindowFeature Developer Tool Helpers

extension MainWindowFeature {
  func normalizedCoordinate(
    _ coordinate: DeveloperToolsFeature.LocationCoordinateInput
  ) -> DeveloperToolsFeature.LocationCoordinateInput? {
    guard let latitude = Double(
      DeveloperToolsFeature.State.trimmed(coordinate.latitude)
    ),
          let longitude = Double(
            DeveloperToolsFeature.State.trimmed(coordinate.longitude)
          )
    else {
      return nil
    }

    return DeveloperToolsFeature.LocationCoordinateInput(
      name: coordinate.name,
      latitude: Self.normalizedCoordinateValue(latitude),
      longitude: Self.normalizedCoordinateValue(longitude)
    )
  }

  static func normalizedCoordinateValue(_ value: Double) -> String {
    String(
      format: "%.6f",
      locale: Locale(identifier: "en_US_POSIX"),
      value
    )
  }
}
