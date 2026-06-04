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
        Text(LocalizedStringResource.mainWindowCommonName)
      }
        .textFieldStyle(.roundedBorder)

      Picker(selection: $formState.runtimeID) {
        ForEach(availableRuntimes) { runtime in
          Text(runtime.name)
            .tag(runtime.id)
        }
      } label: {
        Text(LocalizedStringResource.mainWindowCreateRuntime)
      }

      Picker(selection: $formState.deviceTypeID) {
        ForEach(compatibleDeviceTypes) { deviceType in
          Text(deviceType.name)
            .tag(deviceType.id)
        }
      } label: {
        Text(LocalizedStringResource.mainWindowCreateDeviceType)
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
