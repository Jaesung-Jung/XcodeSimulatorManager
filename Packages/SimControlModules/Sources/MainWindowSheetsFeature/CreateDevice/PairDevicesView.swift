import SimControlLocalization
import SimControlDomain
import SwiftUI

/// Sheet view for choosing a phone simulator and watch simulator to pair.
public struct PairDevicesView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: PairDevicesFormState

  let phoneCandidates: [PairDeviceCandidate]
  let watchCandidates: [PairDeviceCandidate]
  let onSubmit: (PairDevicesFormState) -> Void

  private var selectedPhone: PairDeviceCandidate? {
    phoneCandidates.first { $0.id == formState.phoneDeviceID }
  }

  private var selectedWatch: PairDeviceCandidate? {
    watchCandidates.first { $0.id == formState.watchDeviceID }
  }

  private var canSubmit: Bool {
    selectedPhone != nil && selectedWatch != nil
  }

  /// Creates a pair-devices sheet from candidate phone and watch devices.
  public init(
    formState: PairDevicesFormState,
    phoneCandidates: [PairDeviceCandidate],
    watchCandidates: [PairDeviceCandidate],
    onSubmit: @escaping (PairDevicesFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.phoneCandidates = phoneCandidates
    self.watchCandidates = watchCandidates
    self.onSubmit = onSubmit
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker(selection: $formState.phoneDeviceID) {
            ForEach(phoneCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          } label: {
            Text(.localizable("main_window.common.phone"), bundle: .module)
          }

          Picker(selection: $formState.watchDeviceID) {
            ForEach(watchCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          } label: {
            Text(.localizable("main_window.common.watch"), bundle: .module)
          }
        }

        Section {
          LabeledContent(
            String.localizable("main_window.pair.phone_udid", bundle: .module),
            value: selectedPhone?.udid ?? String.localizable("main_window.common.not_available", bundle: .module)
          )
          LabeledContent(
            String.localizable("main_window.pair.watch_udid", bundle: .module),
            value: selectedWatch?.udid ?? String.localizable("main_window.common.not_available", bundle: .module)
          )
        } header: {
          Text(.localizable("main_window.pair.selected_devices"), bundle: .module)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String.localizable("main_window.pair.title", bundle: .module))
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
            Text(.localizable("main_window.pair.action"), bundle: .module)
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 460, height: 280)
  }
}

// MARK: - PairDevicesView Preview

#if DEBUG

#Preview("Pair Devices Sheet") {
  let phone = PairDeviceCandidate(
    device: SimulatorDevice(
      id: "PREVIEW-PHONE-1",
      udid: "PREVIEW-PHONE-1",
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
  )
  let watch = PairDeviceCandidate(
    device: SimulatorDevice(
      id: "PREVIEW-WATCH-1",
      udid: "PREVIEW-WATCH-1",
      name: "Apple Watch Series 11",
      runtimeID: "com.apple.CoreSimulator.SimRuntime.watchOS-26-4",
      deviceTypeID: "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11",
      platform: .watchOS,
      state: .shutdown,
      isAvailable: true,
      dataPath: nil,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )
  )

  PairDevicesView(
    formState: PairDevicesFormState(
      phoneDeviceID: phone.id,
      watchDeviceID: watch.id
    ),
    phoneCandidates: [phone],
    watchCandidates: [watch]
  ) { _ in }
}

#endif
