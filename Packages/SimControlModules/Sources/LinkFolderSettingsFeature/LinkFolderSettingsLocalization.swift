import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsLinkFolderPath = LocalizedStringResource("settings.link_folder.path", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsLinkFolderPathPrompt = LocalizedStringResource("settings.link_folder.path_prompt", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsLinkFolderSection = LocalizedStringResource("settings.link_folder.section", bundle: .atURL(Bundle.module.bundleURL))
}
#endif
