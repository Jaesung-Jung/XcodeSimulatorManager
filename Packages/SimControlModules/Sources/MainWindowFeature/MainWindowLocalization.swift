import Foundation

#if !Xcode
extension LocalizedStringResource {
  static let mainWindowToolbarCloneSimulator = LocalizedStringResource("main_window.toolbar.clone_simulator", bundle: .atURL(Bundle.module.bundleURL))
  static let mainWindowToolbarCloneSimulatorHelp = LocalizedStringResource(
    "main_window.toolbar.clone_simulator.help",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let mainWindowToolbarCreateSimulator = LocalizedStringResource(
    "main_window.toolbar.create_simulator",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let mainWindowToolbarCreateSimulatorHelp = LocalizedStringResource(
    "main_window.toolbar.create_simulator.help",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let mainWindowToolbarHideInspectorHelp = LocalizedStringResource(
    "main_window.toolbar.hide_inspector.help",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let mainWindowToolbarInspector = LocalizedStringResource("main_window.toolbar.inspector", bundle: .atURL(Bundle.module.bundleURL))
  static let mainWindowToolbarPairSimulators = LocalizedStringResource("main_window.toolbar.pair_simulators", bundle: .atURL(Bundle.module.bundleURL))
  static let mainWindowToolbarPairSimulatorsHelp = LocalizedStringResource(
    "main_window.toolbar.pair_simulators.help",
    bundle: .atURL(Bundle.module.bundleURL)
  )
  static let mainWindowToolbarRefresh = LocalizedStringResource("main_window.toolbar.refresh", bundle: .atURL(Bundle.module.bundleURL))
  static let mainWindowToolbarRefreshHelp = LocalizedStringResource("main_window.toolbar.refresh.help", bundle: .atURL(Bundle.module.bundleURL))
  static let mainWindowToolbarShowInspectorHelp = LocalizedStringResource(
    "main_window.toolbar.show_inspector.help",
    bundle: .atURL(Bundle.module.bundleURL)
  )
}
#endif
