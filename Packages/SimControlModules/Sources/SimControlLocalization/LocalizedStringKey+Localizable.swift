import Foundation
import SwiftUI

public extension LocalizedStringKey {
  /// Creates a localized string key for feature-owned localization resources.
  static func localizable(_ key: String) -> Self {
    LocalizedStringKey(key)
  }
}

public extension String {
  /// Resolves a localized string from a feature-owned bundle.
  static func localizable(
    _ key: String,
    bundle: Bundle,
    _ arguments: CVarArg...
  ) -> String {
    let format = bundle.localizedString(forKey: key, value: nil, table: nil)
    guard !arguments.isEmpty else {
      return format
    }

    return String(format: format, locale: Locale.current, arguments: arguments)
  }
}

public extension Text {
  /// Creates text from a localized format string in a feature-owned bundle.
  static func localizable(
    _ key: String,
    bundle: Bundle,
    _ arguments: CVarArg...
  ) -> Text {
    let format = bundle.localizedString(forKey: key, value: nil, table: nil)
    guard !arguments.isEmpty else {
      return Text(verbatim: format)
    }

    return Text(verbatim: String(format: format, locale: Locale.current, arguments: arguments))
  }
}
