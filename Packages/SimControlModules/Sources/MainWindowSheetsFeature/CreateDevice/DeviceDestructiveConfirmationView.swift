import SimControlLocalization
import SwiftUI

/// Confirmation sheet for destructive simulator device commands.
public struct DeviceDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let titleKey: String
  let messageKey: String
  let actionTitleKey: String
  let systemImage: String
  let confirmationState: DeviceDestructiveConfirmationState
  let onConfirm: (DeviceDestructiveConfirmationState) -> Void

  /// Creates a device confirmation sheet using localized title, message, and action keys.
  public init(
    titleKey: String,
    messageKey: String,
    actionTitleKey: String,
    systemImage: String,
    confirmationState: DeviceDestructiveConfirmationState,
    onConfirm: @escaping (DeviceDestructiveConfirmationState) -> Void
  ) {
    self.titleKey = titleKey
    self.messageKey = messageKey
    self.actionTitleKey = actionTitleKey
    self.systemImage = systemImage
    self.confirmationState = confirmationState
    self.onConfirm = onConfirm
  }

  public var body: some View {
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

// MARK: - DeviceDestructiveConfirmationView Preview

#if DEBUG

#Preview("Erase Simulator Confirmation") {
  DeviceDestructiveConfirmationView(
    titleKey: "main_window.erase.title",
    messageKey: "main_window.erase.message",
    actionTitleKey: "main_window.erase.action",
    systemImage: "eraser",
    confirmationState: DeviceDestructiveConfirmationState(
      deviceID: "PREVIEW-DEVICE-1",
      deviceName: "iPhone 17 Pro",
      deviceUDID: "PREVIEW-DEVICE-1"
    )
  ) { _ in }
}

#endif
