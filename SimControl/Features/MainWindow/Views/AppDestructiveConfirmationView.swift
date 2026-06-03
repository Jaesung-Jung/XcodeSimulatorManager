import SwiftUI

struct AppDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let title: LocalizedStringKey
  let message: LocalizedStringKey
  let actionTitle: LocalizedStringKey
  let systemImage: String
  let confirmationState: MainWindowFeature.AppDestructiveConfirmationState
  let onConfirm: (MainWindowFeature.AppDestructiveConfirmationState) -> Void

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

        Section("App") {
          LabeledContent("Name", value: confirmationState.appName)
          LabeledContent("Bundle ID", value: confirmationState.bundleID)
        }

        Section("Device") {
          LabeledContent("Name", value: confirmationState.deviceName)
          LabeledContent("UDID", value: confirmationState.deviceUDID)
        }

        if let dataContainerPath = confirmationState.dataContainerPath {
          Section("Sandbox") {
            LabeledContent("Path", value: dataContainerPath)
          }
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
    .frame(width: 500, height: confirmationState.dataContainerPath == nil ? 340 : 420)
  }
}
