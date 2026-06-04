import Dependencies
import Foundation

/// User-facing app settings persisted outside feature modules.
public struct SimControlUserSettings: Equatable, Codable, Sendable {
  /// Whether the app should register itself as a login item.
  public var launchesAtLogin: Bool

  /// Whether the menu bar extra is visible.
  public var showsMenuBarExtra: Bool

  /// Whether destructive operations should ask for confirmation.
  public var confirmsDestructiveActions: Bool

  /// The preferred Xcode developer directory path, or an empty string for the active selection.
  public var preferredXcodeDeveloperPath: String

  /// The configured link folder path, or an empty string when unset.
  public var linkFolderPath: String

  /// Whether diagnostic UI and logs are enabled.
  public var enablesDiagnostics: Bool

  /// Creates user settings from persisted values.
  public init(
    launchesAtLogin: Bool,
    showsMenuBarExtra: Bool,
    confirmsDestructiveActions: Bool,
    preferredXcodeDeveloperPath: String,
    linkFolderPath: String,
    enablesDiagnostics: Bool
  ) {
    self.launchesAtLogin = launchesAtLogin
    self.showsMenuBarExtra = showsMenuBarExtra
    self.confirmsDestructiveActions = confirmsDestructiveActions
    self.preferredXcodeDeveloperPath = preferredXcodeDeveloperPath
    self.linkFolderPath = linkFolderPath
    self.enablesDiagnostics = enablesDiagnostics
  }

  /// The default settings used when no persisted settings exist.
  public static var defaults: Self {
    Self(
      launchesAtLogin: false,
      showsMenuBarExtra: true,
      confirmsDestructiveActions: true,
      preferredXcodeDeveloperPath: "",
      linkFolderPath: "",
      enablesDiagnostics: false
    )
  }
}

/// A TCA dependency boundary for loading and saving app settings.
public struct UserSettingsClient: Sendable {
  /// Loads persisted user settings.
  public var load: @Sendable () async -> SimControlUserSettings

  /// Saves user settings.
  public var save: @Sendable (_ settings: SimControlUserSettings) async -> Void

  /// Creates a user settings client from load and save endpoints.
  public init(
    load: @escaping @Sendable () async -> SimControlUserSettings,
    save: @escaping @Sendable (_ settings: SimControlUserSettings) async -> Void
  ) {
    self.load = load
    self.save = save
  }
}

extension UserSettingsClient: TestDependencyKey {
  /// An unimplemented client used by dependency tests unless overridden.
  public static let testValue = UserSettingsClient(
    load: unimplemented(
      "UserSettingsClient.load",
      placeholder: SimControlUserSettings.defaults
    ),
    save: unimplemented("UserSettingsClient.save")
  )
}

extension DependencyValues {
  /// The injected user settings client.
  public var userSettings: UserSettingsClient {
    get { self[UserSettingsClient.self] }
    set { self[UserSettingsClient.self] = newValue }
  }
}
