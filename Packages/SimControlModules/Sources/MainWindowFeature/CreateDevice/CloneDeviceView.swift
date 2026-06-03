import SwiftUI

struct CloneDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: MainWindowFeature.CloneDeviceFormState

  let onSubmit: (MainWindowFeature.CloneDeviceFormState) -> Void

  private var canSubmit: Bool {
    !formState.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  init(
    formState: MainWindowFeature.CloneDeviceFormState,
    onSubmit: @escaping (MainWindowFeature.CloneDeviceFormState) -> Void
  ) {
    self._formState = State(initialValue: formState)
    self.onSubmit = onSubmit
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(formState.sourceName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          TextField("New Name", text: $formState.name)
            .textFieldStyle(.roundedBorder)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Clone Simulator")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Clone") {
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
