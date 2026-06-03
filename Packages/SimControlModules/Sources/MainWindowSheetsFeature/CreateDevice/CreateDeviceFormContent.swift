import SimControlLocalization
import SimControlDomain
import SwiftUI

struct CreateDeviceFormContent: View {
  @Binding var formState: CreateDeviceFormState

  let availableRuntimes: [SimulatorRuntime]
  let compatibleDeviceTypes: [SimulatorDeviceType]
  let compatibilityMessage: Text

  var body: some View {
    Section {
      TextField(text: $formState.name) {
        Text(.localizable("main_window.common.name"), bundle: .module)
      }
        .textFieldStyle(.roundedBorder)

      Picker(selection: $formState.runtimeID) {
        ForEach(availableRuntimes) { runtime in
          Text(runtime.name)
            .tag(runtime.id)
        }
      } label: {
        Text(.localizable("main_window.create.runtime"), bundle: .module)
      }

      Picker(selection: $formState.deviceTypeID) {
        ForEach(compatibleDeviceTypes) { deviceType in
          Text(deviceType.name)
            .tag(deviceType.id)
        }
      } label: {
        Text(.localizable("main_window.create.device_type"), bundle: .module)
      }

      compatibilityMessage
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
