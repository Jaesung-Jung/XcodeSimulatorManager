import SimControlLocalization
import SwiftUI

/// Sheet view for entering the name of a cloned simulator device.
public struct CloneDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: CloneDeviceFormState

  let onSubmit: (CloneDeviceFormState) -> Void

  private var canSubmit: Bool {
    !formState.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

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
            Text(.localizable("main_window.clone.new_name"), bundle: .module)
          }
            .textFieldStyle(.roundedBorder)
        }
      }
      .formStyle(.grouped)
      .navigationTitle(String.localizable("main_window.clone.title", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text(.localizable("main_window.common.cancel"), bundle: .module)
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button {
            onSubmit(formState)
            dismiss()
          } label: {
            Text(.localizable("main_window.clone.action"), bundle: .module)
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 420, height: 190)
  }
}
