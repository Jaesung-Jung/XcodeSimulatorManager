import Foundation
import SimControlClients

public extension UserSettingsClient {
  /// Creates a live user settings client backed by UserDefaults.
  static func live(
    userDefaults: UserDefaults = .standard,
    key: String = "com.js.simctl.userSettings"
  ) -> Self {
    let storage = UserSettingsStorage(
      userDefaults: userDefaults,
      key: key
    )

    return Self(
      load: {
        await storage.load()
      },
      save: { settings in
        await storage.save(settings)
      }
    )
  }
}

private actor UserSettingsStorage {
  let userDefaults: UserDefaults
  let key: String

  init(userDefaults: UserDefaults, key: String) {
    self.userDefaults = userDefaults
    self.key = key
  }

  func load() -> SimControlUserSettings {
    guard let data = userDefaults.data(forKey: key),
          let settings = try? JSONDecoder().decode(SimControlUserSettings.self, from: data)
    else {
      return .defaults
    }

    return settings
  }

  func save(_ settings: SimControlUserSettings) {
    guard let data = try? JSONEncoder().encode(settings) else {
      return
    }

    userDefaults.set(data, forKey: key)
  }
}
