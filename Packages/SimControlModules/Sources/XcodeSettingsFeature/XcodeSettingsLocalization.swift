import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsXcodeDeveloperDirectory = LocalizedStringResource("settings.xcode.developer_directory", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsXcodeDeveloperDirectoryPrompt = LocalizedStringResource("settings.xcode.developer_directory_prompt", bundle: .atURL(Bundle.module.bundleURL))
  static let settingsXcodeSection = LocalizedStringResource("settings.xcode.section", bundle: .atURL(Bundle.module.bundleURL))
}
#endif
