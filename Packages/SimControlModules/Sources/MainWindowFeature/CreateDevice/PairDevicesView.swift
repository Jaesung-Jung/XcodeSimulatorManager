import SwiftUI

struct PairDevicesView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: MainWindowFeature.PairDevicesFormState

  let phoneCandidates: [MainWindowFeature.PairDeviceCandidate]
  let watchCandidates: [MainWindowFeature.PairDeviceCandidate]
  let onSubmit: (MainWindowFeature.PairDevicesFormState) -> Void

  private var selectedPhone: MainWindowFeature.PairDeviceCandidate? {
    phoneCandidates.first { $0.id == formState.phoneDeviceID }
  }

  private var selectedWatch: MainWindowFeature.PairDeviceCandidate? {
    watchCandidates.first { $0.id == formState.watchDeviceID }
  }

  private var canSubmit: Bool {
    selectedPhone != nil && selectedWatch != nil
  }

  init(
    formState: MainWindowFeature.PairDevicesFormState,
    phoneCandidates: [MainWindowFeature.PairDeviceCandidate],
    watchCandidates: [MainWindowFeature.PairDeviceCandidate],
    onSubmit: @escaping (MainWindowFeature.PairDevicesFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.phoneCandidates = phoneCandidates
    self.watchCandidates = watchCandidates
    self.onSubmit = onSubmit
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("Phone", selection: $formState.phoneDeviceID) {
            ForEach(phoneCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          }

          Picker("Watch", selection: $formState.watchDeviceID) {
            ForEach(watchCandidates) { candidate in
              Text(candidate.name)
                .tag(candidate.id)
            }
          }
        }

        Section("Selected Devices") {
          LabeledContent("Phone UDID", value: selectedPhone?.udid ?? "Not available")
          LabeledContent("Watch UDID", value: selectedWatch?.udid ?? "Not available")
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Pair Simulators")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Pair") {
            onSubmit(formState)
            dismiss()
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 460, height: 280)
  }
}
