import SwiftUI

struct RenameDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: MainWindowFeature.RenameDeviceFormState

  let onSubmit: (MainWindowFeature.RenameDeviceFormState) -> Void

  private var canSubmit: Bool {
    let name = formState.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !name.isEmpty && name != formState.currentName
  }

  init(
    formState: MainWindowFeature.RenameDeviceFormState,
    onSubmit: @escaping (MainWindowFeature.RenameDeviceFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.onSubmit = onSubmit
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(formState.currentName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          TextField("Name", text: $formState.name)
            .textFieldStyle(.roundedBorder)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Rename Simulator")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Rename") {
            onSubmit(formState)
            dismiss()
          }
          .disabled(!canSubmit)
        }
      }
    }
    .frame(width: 420, height: 190)
  }
}
