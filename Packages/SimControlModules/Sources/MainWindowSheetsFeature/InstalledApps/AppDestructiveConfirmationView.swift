import SwiftUI

/// Confirmation sheet for destructive installed app commands.
public struct AppDestructiveConfirmationView: View {
  @Environment(\.dismiss) private var dismiss

  let kind: AppDestructiveConfirmationKind
  let systemImage: String
  let confirmationState: AppDestructiveConfirmationState
  let onConfirm: (AppDestructiveConfirmationState) -> Void

  /// Creates an app confirmation sheet using a destructive installed app action kind.
  public init(
    kind: AppDestructiveConfirmationKind,
    systemImage: String,
    confirmationState: AppDestructiveConfirmationState,
    onConfirm: @escaping (AppDestructiveConfirmationState) -> Void
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
            String(localized: .mainWindowCommonName),
            value: confirmationState.appName
          )
          LabeledContent(
            String(localized: .mainWindowCommonBundleId),
            value: confirmationState.bundleID
          )
        } header: {
          Text(.mainWindowCommonApp)
        }

        Section {
          LabeledContent(
            String(localized: .mainWindowCommonName),
            value: confirmationState.deviceName
          )
          LabeledContent(
            String(localized: .mainWindowCommonUdid),
            value: confirmationState.deviceUDID
          )
        } header: {
          Text(.mainWindowCommonDevice)
        }

        if let dataContainerPath = confirmationState.dataContainerPath {
          Section {
            LabeledContent(
              String(localized: .mainWindowCommonPath),
              value: dataContainerPath
            )
          } header: {
            Text(.mainWindowCommonSandbox)
          }
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: kind.title))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(.mainWindowCommonCancel)
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
    .frame(width: 500, height: confirmationState.dataContainerPath == nil ? 340 : 420)
  }
}

// MARK: - AppDestructiveConfirmationView Preview

#if DEBUG

#Preview("Reset Sandbox Confirmation") {
  AppDestructiveConfirmationView(
    kind: .resetSandbox,
    systemImage: "folder.badge.minus",
    confirmationState: AppDestructiveConfirmationState(
      appID: "PREVIEW-DEVICE-1:com.example.preview",
      appName: "Preview App",
      bundleID: "com.example.preview",
      deviceID: "PREVIEW-DEVICE-1",
      deviceName: "iPhone 17 Pro",
      deviceUDID: "PREVIEW-DEVICE-1",
      dataContainerPath: "/tmp/PreviewApp/Data"
    )
  ) { _ in }
}

#endif
