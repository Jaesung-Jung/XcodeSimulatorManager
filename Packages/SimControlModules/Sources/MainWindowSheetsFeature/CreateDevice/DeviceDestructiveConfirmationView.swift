import SwiftUI

/// Confirmation sheet for destructive simulator device commands.
public struct DeviceDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let kind: DeviceDestructiveConfirmationKind
  let systemImage: String
  let confirmationState: DeviceDestructiveConfirmationState
  let onConfirm: (DeviceDestructiveConfirmationState) -> Void

  /// Creates a device confirmation sheet using a destructive device action kind.
  public init(
    kind: DeviceDestructiveConfirmationKind,
    systemImage: String,
    confirmationState: DeviceDestructiveConfirmationState,
    onConfirm: @escaping (DeviceDestructiveConfirmationState) -> Void
  ) {
    self.kind = kind
    self.systemImage = systemImage
    self.confirmationState = confirmationState
    self.onConfirm = onConfirm
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Label {
            Text(kind.message)
          } icon: {
            Image(systemName: systemImage)
          }
        }

        Section {
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonName),
            value: confirmationState.deviceName
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonUdid),
            value: confirmationState.deviceUDID
          )
        } header: {
          Text(LocalizedStringResource.mainWindowCommonDevice)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: kind.title))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(LocalizedStringResource.mainWindowCommonCancel)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(role: .destructive) {
            onConfirm(confirmationState)
            dismiss()
          } label: {
            Text(kind.actionTitle)
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
    kind: .erase,
    systemImage: "eraser",
    confirmationState: DeviceDestructiveConfirmationState(
      deviceID: "PREVIEW-DEVICE-1",
      deviceName: "iPhone 17 Pro",
      deviceUDID: "PREVIEW-DEVICE-1"
    )
  ) { _ in }
}

#endif
