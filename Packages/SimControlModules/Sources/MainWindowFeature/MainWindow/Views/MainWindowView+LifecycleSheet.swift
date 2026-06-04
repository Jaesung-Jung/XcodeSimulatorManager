import ComposableArchitecture
import MainWindowSheetsFeature
import SwiftUI

// MARK: - MainWindowView.LifecycleSheetContent

@MainActor
extension MainWindowView {
  struct LifecycleSheetContent: View {
    let store: StoreOf<MainWindowFeature>
    let sheet: MainWindowFeature.DeviceLifecycleSheet

    var body: some View {
      switch sheet {
      case .create(let formState):
        if let snapshot = store.workspace.snapshot {
          CreateDeviceView(
            formState: formState,
            runtimes: snapshot.runtimes,
            deviceTypes: snapshot.deviceTypes
          ) { formState in
            store.send(.createDeviceSubmitted(formState))
          }
        }
      case .clone(let formState):
        CloneDeviceView(formState: formState) { formState in
          store.send(.cloneDeviceSubmitted(formState))
        }
      case .rename(let formState):
        RenameDeviceView(formState: formState) { formState in
          store.send(.renameDeviceSubmitted(formState))
        }
      case .erase(let confirmationState):
        DeviceDestructiveConfirmationView(
          titleKey: "main_window.erase.title",
          messageKey: "main_window.erase.message",
          actionTitleKey: "main_window.erase.action",
          systemImage: "eraser",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.eraseDeviceConfirmed(confirmationState))
        }
      case .delete(let confirmationState):
        DeviceDestructiveConfirmationView(
          titleKey: "main_window.delete.title",
          messageKey: "main_window.delete.message",
          actionTitleKey: "main_window.delete.action",
          systemImage: "trash",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.deleteDeviceConfirmed(confirmationState))
        }
      case .pair(let formState):
        PairDevicesView(
          formState: formState,
          phoneCandidates: store.pairPhoneCandidates,
          watchCandidates: store.pairWatchCandidates
        ) { formState in
          store.send(.pairDevicesSubmitted(formState))
        }
      case .unpair(let confirmationState):
        UnpairDeviceConfirmationView(confirmationState: confirmationState) { confirmationState in
          store.send(.unpairDeviceConfirmed(confirmationState))
        }
      case .uninstallApp(let confirmationState):
        AppDestructiveConfirmationView(
          titleKey: "main_window.uninstall_app.title",
          messageKey: "main_window.uninstall_app.message",
          actionTitleKey: "main_window.uninstall_app.action",
          systemImage: "trash",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.uninstallAppConfirmed(confirmationState))
        }
      case .resetAppSandbox(let confirmationState):
        AppDestructiveConfirmationView(
          titleKey: "main_window.reset_sandbox.title",
          messageKey: "main_window.reset_sandbox.message",
          actionTitleKey: "main_window.reset_sandbox.action",
          systemImage: "folder.badge.minus",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.resetAppSandboxConfirmed(confirmationState))
        }
      case .installAppOnSimulator(let formState):
        InstallAppOnSimulatorView(
          formState: formState,
          targetCandidates: store.presentedInstallAppTargetCandidates
        ) { formState in
          store.send(.installAppOnSimulatorSubmitted(formState))
        }
      }
    }
  }
}

// MARK: - LifecycleSheetContent Preview

#if DEBUG

#Preview("Clone Sheet Routing") {
  MainWindowView.LifecycleSheetContent(
    store: Store(initialState: MainWindowFeature.State.initial) {
      MainWindowFeature()
    },
    sheet: .clone(
      CloneDeviceFormState(
        sourceDeviceID: "PREVIEW-DEVICE-1",
        sourceName: "iPhone 17 Pro",
        name: "iPhone 17 Pro Copy"
      )
    )
  )
}

#endif
