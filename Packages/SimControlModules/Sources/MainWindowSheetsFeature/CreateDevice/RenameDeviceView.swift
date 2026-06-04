import SwiftUI

/// Sheet view for entering a new simulator device name.
public struct RenameDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: RenameDeviceFormState

  let onSubmit: (RenameDeviceFormState) -> Void

  private var canSubmit: Bool {
    let name = formState.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !name.isEmpty && name != formState.currentName
  }

  /// Creates a rename-device sheet with editable form state.
  public init(
    formState: RenameDeviceFormState,
    onSubmit: @escaping (RenameDeviceFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.onSubmit = onSubmit
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(formState.currentName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          TextField(text: $formState.name) {
            Text(.mainWindowCommonName)
          }
            .textFieldStyle(.roundedBorder)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: .mainWindowRenameTitle))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(.mainWindowCommonCancel)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSubmit(formState)
            dismiss()
          } label: {
            Text(.mainWindowRenameAction)
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 420, height: 190)
  }
}

// MARK: - RenameDeviceView Preview

#if DEBUG

#Preview("Rename Simulator Sheet") {
  RenameDeviceView(
    formState: RenameDeviceFormState(
      deviceID: "PREVIEW-DEVICE-1",
      currentName: "iPhone 17 Pro",
      name: "Renamed Simulator"
    )
  ) { _ in }
}

#endif
