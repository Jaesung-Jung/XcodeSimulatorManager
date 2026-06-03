import Dependencies
import Foundation

/// User-facing app settings persisted outside feature modules.
public struct SimControlUserSettings: Equatable, Codable, Sendable {
  public var launchesAtLogin: Bool
  public var showsMenuBarExtra: Bool
  public var confirmsDestructiveActions: Bool
  public var preferredXcodeDeveloperPath: String
  public var linkFolderPath: String
  public var enablesDiagnostics: Bool

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
  public var load: @Sendable () async -> SimControlUserSettings
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
