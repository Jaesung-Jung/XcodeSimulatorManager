import MainWindowDisplaySupport
import SimControlLocalization
import SimControlDomain
import SwiftUI

/// Sheet view for installing an app bundle on a selected simulator device.
public struct InstallAppOnSimulatorView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: InstallAppTargetFormState

  let targetCandidates: [InstallAppTargetCandidate]
  let onSubmit: (InstallAppTargetFormState) -> Void

  private var selectedTarget: InstallAppTargetCandidate? {
    targetCandidates.first { $0.id == formState.targetDeviceID }
  }

  private var canSubmit: Bool {
    selectedTarget != nil
  }

  /// Creates an install-app sheet from a source app and target simulator candidates.
  public init(
    formState: InstallAppTargetFormState,
    targetCandidates: [InstallAppTargetCandidate],
    onSubmit: @escaping (InstallAppTargetFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.targetCandidates = targetCandidates
    self.onSubmit = onSubmit
  }

  public var body: some View {
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

// MARK: - InstallAppOnSimulatorView Preview

#if DEBUG

#Preview("Install App Sheet") {
  let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    deviceTypeID: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: nil,
    logPath: nil,
    lastBootedAt: nil,
    dataPathSize: nil
  )

  InstallAppOnSimulatorView(
    formState: InstallAppTargetFormState(
      sourceAppID: "PREVIEW-DEVICE-1:com.example.preview",
      sourceDeviceID: device.id,
      appName: "Preview App",
      bundleID: "com.example.preview",
      appBundlePath: URL(fileURLWithPath: "/tmp/Preview.app"),
      targetDeviceID: device.id,
      launchAfterInstall: true
    ),
    targetCandidates: [
      InstallAppTargetCandidate(device: device)
    ]
  ) { _ in }
}

#endif
