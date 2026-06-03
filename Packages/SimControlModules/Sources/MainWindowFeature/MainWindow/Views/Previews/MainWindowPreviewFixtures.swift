import Foundation
import SimControlClients
import SimControlDomain

#if DEBUG
import ComposableArchitecture

extension MainWindowFeature.State {
  static var preview: MainWindowFeature.State {
    MainWindowFeature.State(
      snapshot: MainWindowPreviewFixtures.snapshot,
      refreshState: .idle,
      selectedDeviceID: MainWindowPreviewFixtures.device.id,
      selectedAppID: nil,
      lastCommandResults: MainWindowPreviewFixtures.commandResults,
      installedAppsAvailability: .notLoaded
    )
  }
}

extension Store where State == MainWindowFeature.State, Action == MainWindowFeature.Action {
  @MainActor
  static var mainWindowPreview: StoreOf<MainWindowFeature> {
    Store(initialState: .preview) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        MainWindowPreviewFixtures.refreshResult
      }
      $0.coreSimulatorService.openSimulatorApp = {
        MainWindowPreviewFixtures.openSimulatorCommandResult
      }
      $0.coreSimulatorService.bootDevice = { _ in
        MainWindowPreviewFixtures.commandResults[1]
      }
      $0.coreSimulatorService.bootDeviceIfNeeded = { _ in
        MainWindowPreviewFixtures.bootStatusCommandResult
      }
      $0.coreSimulatorService.shutdownDevice = { _ in
        MainWindowPreviewFixtures.commandResults[1]
      }
      $0.coreSimulatorService.createDevice = { _, _, _ in
        MainWindowPreviewFixtures.createDeviceCommandResult
      }
      $0.coreSimulatorService.cloneDevice = { _, _ in
        MainWindowPreviewFixtures.cloneDeviceCommandResult
      }
      $0.coreSimulatorService.renameDevice = { _, _ in
        MainWindowPreviewFixtures.renameDeviceCommandResult
      }
      $0.coreSimulatorService.eraseDevice = { _ in
        MainWindowPreviewFixtures.eraseDeviceCommandResult
      }
      $0.coreSimulatorService.deleteDevice = { _ in
        MainWindowPreviewFixtures.deleteDeviceCommandResult
      }
      $0.coreSimulatorService.pairDevices = { _, _ in
        MainWindowPreviewFixtures.pairDevicesCommandResult
      }
      $0.coreSimulatorService.unpairDevice = { _ in
        MainWindowPreviewFixtures.unpairDeviceCommandResult
      }
      $0.coreSimulatorService.launchApp = { _, _ in
        MainWindowPreviewFixtures.launchAppCommandResult
      }
      $0.coreSimulatorService.terminateApp = { _, _ in
        MainWindowPreviewFixtures.terminateAppCommandResult
      }
      $0.coreSimulatorService.uninstallApp = { _, _ in
        MainWindowPreviewFixtures.uninstallAppCommandResult
      }
      $0.coreSimulatorService.installApp = { _, _ in
        MainWindowPreviewFixtures.installAppCommandResult
      }
      $0.appSandboxReset.resetSandbox = { _ in
        MainWindowPreviewFixtures.resetSandboxCommandResult
      }
    }
  }
}

enum MainWindowPreviewFixtures {}

#endif
