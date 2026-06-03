import MainWindowDisplaySupport
import SimControlLocalization
import SwiftUI

struct InstallAppOnSimulatorView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: MainWindowFeature.InstallAppTargetFormState

  let targetCandidates: [MainWindowFeature.InstallAppTargetCandidate]
  let onSubmit: (MainWindowFeature.InstallAppTargetFormState) -> Void

  private var selectedTarget: MainWindowFeature.InstallAppTargetCandidate? {
    targetCandidates.first { $0.id == formState.targetDeviceID }
  }

  private var canSubmit: Bool {
    selectedTarget != nil
  }

  init(
    formState: MainWindowFeature.InstallAppTargetFormState,
    targetCandidates: [MainWindowFeature.InstallAppTargetCandidate],
    onSubmit: @escaping (MainWindowFeature.InstallAppTargetFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.targetCandidates = targetCandidates
    self.onSubmit = onSubmit
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          LabeledContent(
            String.localizable("main_window.common.name", bundle: .module),
            value: formState.appName
          )
          LabeledContent(
            String.localizable("main_window.common.bundle_id", bundle: .module),
            value: formState.bundleID
          )
          LabeledContent(
            String.localizable("main_window.common.bundle", bundle: .module),
            value: formState.appBundlePath.path
          )
        } header: {
          Text(.localizable("main_window.common.app"), bundle: .module)
        }

        Section {
          Picker(selection: $formState.targetDeviceID) {
            ForEach(targetCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          } label: {
            Text(.localizable("main_window.common.simulator"), bundle: .module)
          }

          Toggle(isOn: $formState.launchAfterInstall) {
            Text(.localizable("main_window.install_app.launch_after_install"), bundle: .module)
          }

          LabeledContent(
            String.localizable("main_window.common.state", bundle: .module),
            value: selectedTarget?.state.displayTitle ?? String.localizable(
              "main_window.common.not_available",
              bundle: .module
            )
          )
          LabeledContent(
            String.localizable("main_window.common.udid", bundle: .module),
            value: selectedTarget?.udid ?? String.localizable("main_window.common.not_available", bundle: .module)
          )
        } header: {
          Text(.localizable("main_window.common.target"), bundle: .module)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String.localizable("main_window.install_app.title", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(.localizable("main_window.common.cancel"), bundle: .module)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSubmit(formState)
            dismiss()
          } label: {
            Text(.localizable("main_window.install_app.action"), bundle: .module)
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 520, height: 420)
  }
}
