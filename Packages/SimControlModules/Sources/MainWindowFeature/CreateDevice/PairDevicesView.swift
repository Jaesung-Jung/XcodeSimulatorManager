import SimControlLocalization
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
