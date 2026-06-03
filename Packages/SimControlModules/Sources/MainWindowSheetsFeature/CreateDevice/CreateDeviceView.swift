import SimControlLocalization
import SimControlDomain
import SwiftUI

/// Sheet view for creating a simulator device from runtime and device type selections.
public struct CreateDeviceView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var formState: CreateDeviceFormState

  let runtimes: [SimulatorRuntime]
  let deviceTypes: [SimulatorDeviceType]
  let onSubmit: (CreateDeviceFormState) -> Void

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

  private var compatibilityMessage: Text {
    guard let selectedRuntime else {
      return Text(.localizable("main_window.create.no_runtime"), bundle: .module)
    }

    guard !selectedRuntime.supportedDeviceTypeIDs.isEmpty else {
      return Text(.localizable("main_window.create.unreported_compatibility"), bundle: .module)
    }

    return Text.localizable(
      "main_window.create.compatible_device_types_count",
      bundle: .module,
      compatibleDeviceTypes.count
    )
  }

  private var canSubmit: Bool {
    selectedRuntime != nil && selectedDeviceType != nil
  }

  /// Creates a create-device sheet and normalizes the initial runtime and device type selections.
  public init(
    formState: CreateDeviceFormState,
    runtimes: [SimulatorRuntime],
    deviceTypes: [SimulatorDeviceType],
    onSubmit: @escaping (CreateDeviceFormState) -> Void
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

  public var body: some View {
    NavigationStack {
      Form {
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
      .formStyle(.grouped)
      .navigationTitle(String.localizable("main_window.create.title", bundle: .module))
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
            Text(.localizable("main_window.create.action"), bundle: .module)
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
    _ formState: CreateDeviceFormState,
    runtimes: [SimulatorRuntime],
    deviceTypes: [SimulatorDeviceType]
  ) -> CreateDeviceFormState {
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

    return CreateDeviceFormState(
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
