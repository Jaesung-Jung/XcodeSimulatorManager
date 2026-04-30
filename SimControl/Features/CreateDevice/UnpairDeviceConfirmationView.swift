import SwiftUI

struct UnpairDeviceConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let confirmationState: MainWindowFeature.UnpairDeviceConfirmationState
  let onConfirm: (MainWindowFeature.UnpairDeviceConfirmationState) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Label {
            Text("Remove this watch and phone pair.")
          } icon: {
            Image(systemName: "link.badge.minus")
          }
        }

        Section("Phone") {
          LabeledContent("Name", value: confirmationState.phoneName)
          LabeledContent("UDID", value: confirmationState.phoneUDID)
        }

        Section("Watch") {
          LabeledContent("Name", value: confirmationState.watchName)
          LabeledContent("UDID", value: confirmationState.watchUDID)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Unpair Simulators")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(role: .destructive) {
            onConfirm(confirmationState)
            dismiss()
          } label: {
            Text("Unpair")
          }
        }
      }
    }
    .frame(width: 460, height: 340)
  }
}
