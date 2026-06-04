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

// MARK: - CreateDeviceFormContent Preview

#if DEBUG

#Preview("Create Device Form Content") {
  let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"]
  )
  let deviceType = SimulatorDeviceType(
    id: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )

  Form {
    CreateDeviceFormContent(
      formState: .constant(
        CreateDeviceFormState(
          name: "Preview iPhone",
          runtimeID: runtime.id,
          deviceTypeID: deviceType.id
        )
      ),
      availableRuntimes: [runtime],
      compatibleDeviceTypes: [deviceType],
      compatibilityMessage: Text("1 compatible device type")
    )
  }
  .formStyle(.grouped)
  .frame(width: 460)
}

#endif
