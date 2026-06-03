import SimControlLocalization
import SwiftUI

struct DeviceDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let titleKey: String
  let messageKey: String
  let actionTitleKey: String
  let systemImage: String
  let confirmationState: MainWindowFeature.DeviceDestructiveConfirmationState
  let onConfirm: (MainWindowFeature.DeviceDestructiveConfirmationState) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Label {
            Text(.localizable(messageKey), bundle: .module)
          } icon: {
            Image(systemName: systemImage)
          }
        }

        Section {
          LabeledContent(
            String.localizable("main_window.common.name", bundle: .module),
            value: confirmationState.deviceName
          )
          LabeledContent(
            String.localizable("main_window.common.udid", bundle: .module),
            value: confirmationState.deviceUDID
          )
        } header: {
          Text(.localizable("main_window.common.device"), bundle: .module)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String.localizable(titleKey, bundle: .module))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(.localizable("main_window.common.cancel"), bundle: .module)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(role: .destructive) {
            onConfirm(confirmationState)
            dismiss()
          } label: {
            Text(.localizable(actionTitleKey), bundle: .module)
          }
        }
      }
    }
    .frame(width: 460, height: 260)
  }
}
