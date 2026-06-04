import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsGeneralLaunchAtLogin = LocalizedStringResource("settings.general.launch_at_login", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsGeneralSection = LocalizedStringResource("settings.general.section", bundle: .atURL(Bundle.module.bundleURL))
}
#endif
