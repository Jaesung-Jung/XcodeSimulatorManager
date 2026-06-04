import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsSafetyConfirmDestructiveActions = LocalizedStringResource("settings.safety.confirm_destructive_actions", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsSafetySection = LocalizedStringResource("settings.safety.section", bundle: .atURL(Bundle.module.bundleURL))
}
#endif
