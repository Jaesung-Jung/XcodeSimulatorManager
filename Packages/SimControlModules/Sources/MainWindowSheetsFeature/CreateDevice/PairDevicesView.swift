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
            Text(LocalizedStringResource.mainWindowCommonPhone)
          }

          Picker(selection: $formState.watchDeviceID) {
            ForEach(watchCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          } label: {
            Text(LocalizedStringResource.mainWindowCommonWatch)
          }
        }

        Section {
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowPairPhoneUdid),
            value: selectedPhone?.udid ?? String(localized: LocalizedStringResource.mainWindowCommonNotAvailable)
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowPairWatchUdid),
            value: selectedWatch?.udid ?? String(localized: LocalizedStringResource.mainWindowCommonNotAvailable)
          )
        } header: {
          Text(LocalizedStringResource.mainWindowPairSelectedDevices)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: LocalizedStringResource.mainWindowPairTitle))
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
            Text(LocalizedStringResource.mainWindowPairAction)
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
