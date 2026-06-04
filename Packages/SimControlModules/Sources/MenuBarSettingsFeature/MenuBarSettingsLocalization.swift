import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsMenuBarSection = LocalizedStringResource("settings.menu_bar.section", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsMenuBarShowMenuBarExtra = LocalizedStringResource(
    "settings.menu_bar.show_menu_bar_extra",
    bundle: .atURL(Bundle.module.bundleURL)
  )
}
#endif
