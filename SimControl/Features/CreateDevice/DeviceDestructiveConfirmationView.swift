import SwiftUI

struct DeviceDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let title: LocalizedStringKey
  let message: LocalizedStringKey
  let actionTitle: LocalizedStringKey
  let systemImage: String
  let confirmationState: MainWindowFeature.DeviceDestructiveConfirmationState
  let onConfirm: (MainWindowFeature.DeviceDestructiveConfirmationState) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Label {
            Text(message)
          } icon: {
            Image(systemName: systemImage)
          }
        }

        Section("Device") {
          LabeledContent("Name", value: confirmationState.deviceName)
          LabeledContent("UDID", value: confirmationState.deviceUDID)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(title)
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
            Text(actionTitle)
          }
        }
      }
    }
    .frame(width: 460, height: 260)
  }
}
