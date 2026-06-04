import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let settingsDiagnosticsEnableDiagnostics = LocalizedStringResource(
    "settings.diagnostics.enable_diagnostics",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let settingsDiagnosticsSection = LocalizedStringResource("settings.diagnostics.section", bundle: .atURL(Bundle.module.bundleURL))
}
#endif
