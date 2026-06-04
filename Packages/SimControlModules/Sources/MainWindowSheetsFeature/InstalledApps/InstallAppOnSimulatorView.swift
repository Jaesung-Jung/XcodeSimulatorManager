import MainWindowDisplaySupport
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
            String(localized: LocalizedStringResource.mainWindowCommonName),
            value: formState.appName
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonBundleId),
            value: formState.bundleID
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonBundle),
            value: formState.appBundlePath.path
          )
        } header: {
          Text(LocalizedStringResource.mainWindowCommonApp)
        }

        Section {
          Picker(selection: $formState.targetDeviceID) {
            ForEach(targetCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          } label: {
            Text(LocalizedStringResource.mainWindowCommonSimulator)
          }

          Toggle(isOn: $formState.launchAfterInstall) {
            Text(LocalizedStringResource.mainWindowInstallAppLaunchAfterInstall)
          }

          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonState),
            value: selectedTarget?.state.displayTitle ?? String(localized: LocalizedStringResource.mainWindowCommonNotAvailable)
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonUdid),
            value: selectedTarget?.udid ?? String(localized: LocalizedStringResource.mainWindowCommonNotAvailable)
          )
        } header: {
          Text(LocalizedStringResource.mainWindowCommonTarget)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: LocalizedStringResource.mainWindowInstallAppTitle))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(LocalizedStringResource.mainWindowCommonCancel)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSubmit(formState)
            dismiss()
          } label: {
            Text(LocalizedStringResource.mainWindowInstallAppAction)
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
