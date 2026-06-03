import SimControlLocalization
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
            Text(.localizable("main_window.unpair.message"), bundle: .module)
          } icon: {
            Image(systemName: "link.badge.minus")
          }
        }

        Section {
          LabeledContent(
            String.localizable("main_window.common.name", bundle: .module),
            value: confirmationState.phoneName
          )
          LabeledContent(
            String.localizable("main_window.common.udid", bundle: .module),
            value: confirmationState.phoneUDID
          )
        } header: {
          Text(.localizable("main_window.common.phone"), bundle: .module)
        }

        Section {
          LabeledContent(
            String.localizable("main_window.common.name", bundle: .module),
            value: confirmationState.watchName
          )
          LabeledContent(
            String.localizable("main_window.common.udid", bundle: .module),
            value: confirmationState.watchUDID
          )
        } header: {
          Text(.localizable("main_window.common.watch"), bundle: .module)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String.localizable("main_window.unpair.title", bundle: .module))
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
            Text(.localizable("main_window.unpair.action"), bundle: .module)
          }
        }
      }
    }
    .frame(width: 460, height: 340)
  }
}
