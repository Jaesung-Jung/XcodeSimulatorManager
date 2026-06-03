import SimControlLocalization
import SwiftUI

struct AppDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let titleKey: String
  let messageKey: String
  let actionTitleKey: String
  let systemImage: String
  let confirmationState: MainWindowFeature.AppDestructiveConfirmationState
  let onConfirm: (MainWindowFeature.AppDestructiveConfirmationState) -> Void

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
            value: confirmationState.appName
          )
          LabeledContent(
            String.localizable("main_window.common.bundle_id", bundle: .module),
            value: confirmationState.bundleID
          )
        } header: {
          Text(.localizable("main_window.common.app"), bundle: .module)
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

        if let dataContainerPath = confirmationState.dataContainerPath {
          Section {
            LabeledContent(
              String.localizable("main_window.common.path", bundle: .module),
              value: dataContainerPath
            )
          } header: {
            Text(.localizable("main_window.common.sandbox"), bundle: .module)
          }
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
    .frame(width: 500, height: confirmationState.dataContainerPath == nil ? 340 : 420)
  }
}
