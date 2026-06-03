import Foundation
import MainWindowWorkflows
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
      $0.inventoryWorkflow = MainWindowPreviewFixtures.inventoryWorkflow
      $0.deviceLifecycleWorkflow = MainWindowPreviewFixtures.deviceLifecycleWorkflow
      $0.installedAppWorkflow = MainWindowPreviewFixtures.installedAppWorkflow
      $0.developerToolWorkflow = MainWindowPreviewFixtures.developerToolWorkflow
      $0.pathActionWorkflow = MainWindowPreviewFixtures.pathActionWorkflow
    }
  }
}

enum MainWindowPreviewFixtures {}

extension MainWindowPreviewFixtures {
  static var inventoryWorkflow: InventoryWorkflowClient {
    InventoryWorkflowClient(
      refresh: {
        refreshResult
      },
      openSimulatorApp: {
        openSimulatorCommandResult
      }
    )
  }

  static var deviceLifecycleWorkflow: DeviceLifecycleWorkflowClient {
    DeviceLifecycleWorkflowClient(
      bootDevice: { _ in
        deviceLifecycleResult(commandResult: commandResults[1], preferredSelectedDeviceID: nil)
      },
      shutdownDevice: { _ in
        deviceLifecycleResult(commandResult: commandResults[1], preferredSelectedDeviceID: nil)
      },
      createDevice: { _, _, _ in
        deviceLifecycleResult(commandResult: createDeviceCommandResult, preferredSelectedDeviceID: "PREVIEW-DEVICE-CREATED")
      },
      cloneDevice: { _, _ in
        deviceLifecycleResult(commandResult: cloneDeviceCommandResult, preferredSelectedDeviceID: "PREVIEW-DEVICE-CLONED")
      },
      renameDevice: { _, _ in
        deviceLifecycleResult(commandResult: renameDeviceCommandResult, preferredSelectedDeviceID: nil)
      },
      eraseDevice: { _ in
        deviceLifecycleResult(commandResult: eraseDeviceCommandResult, preferredSelectedDeviceID: nil)
      },
      deleteDevice: { _ in
        deviceLifecycleResult(commandResult: deleteDeviceCommandResult, preferredSelectedDeviceID: nil)
      },
      pairDevices: { _, _ in
        deviceLifecycleResult(commandResult: pairDevicesCommandResult, preferredSelectedDeviceID: nil)
      },
      unpairDevice: { _ in
        deviceLifecycleResult(commandResult: unpairDeviceCommandResult, preferredSelectedDeviceID: nil)
      }
    )
  }

  static var installedAppWorkflow: InstalledAppWorkflowClient {
    InstalledAppWorkflowClient(
      launchApp: { deviceID, appID, _, deviceState in
        let commandResults = deviceState == .shutdown
          ? [bootStatusCommandResult, launchAppCommandResult]
          : [launchAppCommandResult]
        return installedAppResult(commandResults: commandResults, preferredSelectedDeviceID: deviceID, preferredSelectedAppID: appID)
      },
      terminateApp: { deviceID, appID, _ in
        installedAppResult(commandResults: [terminateAppCommandResult], preferredSelectedDeviceID: deviceID, preferredSelectedAppID: appID)
      },
      uninstallApp: { deviceID, appID, _ in
        installedAppResult(
          commandResults: [uninstallAppCommandResult],
          preferredSelectedDeviceID: deviceID,
          preferredSelectedAppID: uninstallAppCommandResult.succeeded ? nil : appID
        )
      },
      resetSandbox: { deviceID, appID, _ in
        installedAppResult(commandResults: [resetSandboxCommandResult], preferredSelectedDeviceID: deviceID, preferredSelectedAppID: appID)
      },
      installAppOnSimulator: { request in
        let commandResults = request.targetDeviceState == .shutdown
          ? [bootStatusCommandResult, installAppCommandResult]
          : [installAppCommandResult]
        return installedAppResult(
          commandResults: commandResults,
          preferredSelectedDeviceID: installAppCommandResult.succeeded ? request.targetDeviceID : nil,
          preferredSelectedAppID: installAppCommandResult.succeeded ? "\(request.targetDeviceID):\(request.bundleID)" : nil
        )
      }
    )
  }

  static var developerToolWorkflow: DeveloperToolWorkflowClient {
    DeveloperToolWorkflowClient(
      openURL: { deviceID, _, _ in
        developerToolResult(commandResults: [openSimulatorCommandResult], preferredSelectedDeviceID: deviceID)
      },
      pushNotification: { deviceID, _, _, _ in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      },
      setPrivacyPermission: { deviceID, _, _, _, _ in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      },
      setLocation: { deviceID, _, _ in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      },
      clearLocation: { deviceID, _ in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      },
      setStatusBarOverride: { deviceID, _ in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      },
      clearStatusBarOverride: { deviceID in
        developerToolResult(commandResults: [commandResults[1]], preferredSelectedDeviceID: deviceID)
      }
    )
  }

  static var pathActionWorkflow: PathActionWorkflowClient {
    PathActionWorkflowClient(
      runDevicePathAction: { _, _, _ in
        [commandResults[1]]
      },
      copyValue: { _, _ in
        [commandResults[1]]
      },
      runAppContainerPathAction: { _ in
        [commandResults[1]]
      }
    )
  }

  static func deviceLifecycleResult(
    commandResult: CommandResult,
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) -> DeviceLifecycleWorkflowResult {
    DeviceLifecycleWorkflowResult(
      commandResult: commandResult,
      refreshResult: refreshResult,
      preferredSelectedDeviceID: preferredSelectedDeviceID
    )
  }

  static func installedAppResult(
    commandResults: [CommandResult],
    preferredSelectedDeviceID: SimulatorDevice.ID?,
    preferredSelectedAppID: InstalledApp.ID?
  ) -> InstalledAppWorkflowResult {
    InstalledAppWorkflowResult(
      commandResults: commandResults,
      refreshResult: refreshResult,
      preferredSelectedDeviceID: preferredSelectedDeviceID,
      preferredSelectedAppID: preferredSelectedAppID
    )
  }

  static func developerToolResult(
    commandResults: [CommandResult],
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) -> DeveloperToolWorkflowResult {
    DeveloperToolWorkflowResult(
      commandResults: commandResults,
      refreshResult: refreshResult,
      preferredSelectedDeviceID: preferredSelectedDeviceID
    )
  }
}

#endif
