import SwiftUI

/// Sheet view for entering the name of a cloned simulator device.
public struct CloneDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: CloneDeviceFormState

  let onSubmit: (CloneDeviceFormState) -> Void

  private var canSubmit: Bool { !formState.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

  /// Creates a clone-device sheet with editable form state.
  public init(
    formState: CloneDeviceFormState,
    onSubmit: @escaping (CloneDeviceFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.onSubmit = onSubmit
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(formState.sourceName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          TextField(text: $formState.name) {
            Text(LocalizedStringResource.mainWindowCloneNewName)
          }
            .textFieldStyle(.roundedBorder)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: LocalizedStringResource.mainWindowCloneTitle))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(LocalizedStringResource.mainWindowCommonCancel)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSubmit(formState)
            dismiss()
          } label: {
            Text(LocalizedStringResource.mainWindowCloneAction)
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 420, height: 190)
  }
}

// MARK: - CloneDeviceView Preview

#if DEBUG

#Preview("Clone Simulator Sheet") {
  CloneDeviceView(
    formState: CloneDeviceFormState(
      sourceDeviceID: "PREVIEW-DEVICE-1",
      sourceName: "iPhone 17 Pro",
      name: "iPhone 17 Pro Copy"
    )
  ) { _ in }
}

#endif
