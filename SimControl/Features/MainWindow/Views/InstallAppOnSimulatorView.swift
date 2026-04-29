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
        Section("App") {
          LabeledContent("Name", value: formState.appName)
          LabeledContent("Bundle ID", value: formState.bundleID)
          LabeledContent("Bundle", value: formState.appBundlePath.path)
        }

        Section("Target") {
          Picker("Simulator", selection: $formState.targetDeviceID) {
            ForEach(targetCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          }

          Toggle("Launch after install", isOn: $formState.launchAfterInstall)

          LabeledContent("State", value: selectedTarget?.state.displayTitle ?? "Not available")
          LabeledContent("UDID", value: selectedTarget?.udid ?? "Not available")
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Install App")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Install") {
            onSubmit(formState)
            dismiss()
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 520, height: 420)
  }
}
