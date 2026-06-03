/// A platform family supported by CoreSimulator inventory.
///
/// The value is intentionally small and tolerant of unknown platform strings so
/// the parser can keep inventory visible even when Xcode adds new platforms.
enum SimulatorPlatform: String, Equatable, Hashable {
  /// iOS simulator platform.
  case iOS

  /// watchOS simulator platform.
  case watchOS

  /// tvOS simulator platform.
  case tvOS

  /// visionOS simulator platform.
  case visionOS

  /// A platform that could not be mapped to a known case.
  case unknown
}

/// A simulator runtime installed in the active Xcode environment.
///
/// Runtime values are based on structured `simctl list -j` fields where
/// possible. Unavailable runtimes remain part of the snapshot so the UI can
/// explain compatibility and environment issues.
struct SimulatorRuntime: Identifiable, Equatable, Hashable {
  /// The CoreSimulator runtime identifier.
  let id: String

  /// The user-visible runtime name.
  let name: String

  /// The runtime version string.
  let version: String

  /// The runtime build version string.
  let buildVersion: String

  /// The platform family for the runtime.
  let platform: SimulatorPlatform

  /// Indicates whether CoreSimulator reports the runtime as available.
  let isAvailable: Bool

  /// Device type identifiers reported as compatible with this runtime.
  let supportedDeviceTypeIDs: [String]
}
