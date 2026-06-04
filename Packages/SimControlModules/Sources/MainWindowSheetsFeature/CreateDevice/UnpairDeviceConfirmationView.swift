import SwiftUI

/// Confirmation sheet for unpairing a phone/watch simulator pair.
public struct UnpairDeviceConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let confirmationState: UnpairDeviceConfirmationState
  let onConfirm: (UnpairDeviceConfirmationState) -> Void

  /// Creates an unpair confirmation sheet for a simulator pair.
  public init(
    confirmationState: UnpairDeviceConfirmationState,
    onConfirm: @escaping (UnpairDeviceConfirmationState) -> Void
  ) {
    self.confirmationState = confirmationState
    self.onConfirm = onConfirm
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Label {
            Text(LocalizedStringResource.mainWindowUnpairMessage)
          } icon: {
            Image(systemName: "link.badge.minus")
          }
        }

        Section {
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonName),
            value: confirmationState.phoneName
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonUdid),
            value: confirmationState.phoneUDID
          )
        } header: {
          Text(LocalizedStringResource.mainWindowCommonPhone)
        }

        Section {
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonName),
            value: confirmationState.watchName
          )
          LabeledContent(
            String(localized: LocalizedStringResource.mainWindowCommonUdid),
            value: confirmationState.watchUDID
          )
        } header: {
          Text(LocalizedStringResource.mainWindowCommonWatch)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: LocalizedStringResource.mainWindowUnpairTitle))
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
            Text(LocalizedStringResource.mainWindowUnpairAction)
          }
        }
      }
    }
    .frame(width: 460, height: 340)
  }
}

// MARK: - UnpairDeviceConfirmationView Preview

#if DEBUG

#Preview("Unpair Device Confirmation") {
  UnpairDeviceConfirmationView(
    confirmationState: UnpairDeviceConfirmationState(
      pairID: "PREVIEW-PAIR-1",
      phoneName: "iPhone 17 Pro",
      phoneUDID: "PREVIEW-PHONE-1",
      watchName: "Apple Watch Series 11",
      watchUDID: "PREVIEW-WATCH-1"
    )
  ) { _ in }
}

#endif
