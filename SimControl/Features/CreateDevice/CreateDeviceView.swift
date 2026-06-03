import SwiftUI

struct CreateDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: MainWindowFeature.CreateDeviceFormState

  let runtimes: [SimulatorRuntime]
  let deviceTypes: [SimulatorDeviceType]
  let onSubmit: (MainWindowFeature.CreateDeviceFormState) -> Void

  private var availableRuntimes: [SimulatorRuntime] {
    runtimes.filter(\.isAvailable)
  }

  private var selectedRuntime: SimulatorRuntime? {
    availableRuntimes.first { $0.id == formState.runtimeID }
  }

  private var compatibleDeviceTypes: [SimulatorDeviceType] {
    guard let selectedRuntime else {
      return []
    }

    guard !selectedRuntime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(selectedRuntime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }

  private var selectedDeviceType: SimulatorDeviceType? {
    compatibleDeviceTypes.first { $0.id == formState.deviceTypeID }
  }

  private var compatibilityTitle: String {
    guard let selectedRuntime else {
      return "No available runtime selected."
    }

    guard !selectedRuntime.supportedDeviceTypeIDs.isEmpty else {
      return "Runtime compatibility is not reported; all device types are shown."
    }

    return "\(compatibleDeviceTypes.count) compatible device types"
  }

  private var canSubmit: Bool {
    selectedRuntime != nil && selectedDeviceType != nil
  }

  init(
    formState: MainWindowFeature.CreateDeviceFormState,
    runtimes: [SimulatorRuntime],
    deviceTypes: [SimulatorDeviceType],
    onSubmit: @escaping (MainWindowFeature.CreateDeviceFormState) -> Void
  ) {
    let normalizedFormState = Self.normalizedFormState(
      formState,
      runtimes: runtimes,
      deviceTypes: deviceTypes
    )

    self._formState = State(initialValue: normalizedFormState)
    self.runtimes = runtimes
    self.deviceTypes = deviceTypes
    self.onSubmit = onSubmit
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Name", text: $formState.name)
            .textFieldStyle(.roundedBorder)

          Picker("Runtime", selection: $formState.runtimeID) {
            ForEach(availableRuntimes) { runtime in
              Text(runtime.name)
                .tag(runtime.id)
            }
          }

          Picker("Device Type", selection: $formState.deviceTypeID) {
            ForEach(compatibleDeviceTypes) { deviceType in
              Text(deviceType.name)
                .tag(deviceType.id)
            }
          }

          Text(compatibilityTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Create Simulator")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            onSubmit(formState)
            dismiss()
          }
          .disabled(!canSubmit)
        }
      }
      .onChange(of: formState.runtimeID) {
        selectCompatibleDeviceTypeIfNeeded()
      }
    }
    .frame(width: 460, height: 280)
  }

  private func selectCompatibleDeviceTypeIfNeeded() {
    guard selectedDeviceType == nil,
          let firstDeviceType = compatibleDeviceTypes.first
    else {
      return
    }

    formState.deviceTypeID = firstDeviceType.id
  }

  private static func normalizedFormState(
    _ formState: MainWindowFeature.CreateDeviceFormState,
    runtimes: [SimulatorRuntime],
    deviceTypes: [SimulatorDeviceType]
  ) -> MainWindowFeature.CreateDeviceFormState {
    let availableRuntimes = runtimes.filter(\.isAvailable)
    let runtime = availableRuntimes.first { $0.id == formState.runtimeID }
      ?? availableRuntimes.first
    guard let runtime else {
      return formState
    }

    let compatibleDeviceTypes = compatibleDeviceTypes(
      for: runtime,
      in: deviceTypes
    )
    let deviceType = compatibleDeviceTypes.first { $0.id == formState.deviceTypeID }
      ?? compatibleDeviceTypes.first

    return MainWindowFeature.CreateDeviceFormState(
      name: formState.name,
      runtimeID: runtime.id,
      deviceTypeID: deviceType?.id ?? formState.deviceTypeID
    )
  }

  private static func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }
}
