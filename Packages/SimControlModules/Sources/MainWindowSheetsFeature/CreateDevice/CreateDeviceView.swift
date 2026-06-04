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
      return Text(.mainWindowCreateNoRuntime)
    }

    guard !selectedRuntime.supportedDeviceTypeIDs.isEmpty else {
      return Text(.mainWindowCreateUnreportedCompatibility)
    }

    return Text(.mainWindowCreateCompatibleDeviceTypesCount(count: compatibleDeviceTypes.count))
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
        CreateDeviceFormContent(
          formState: $formState,
          availableRuntimes: availableRuntimes,
          compatibleDeviceTypes: compatibleDeviceTypes,
          compatibilityMessage: compatibilityMessage
        )
      }
      .formStyle(.grouped)
      .navigationTitle(String(localized: .mainWindowCreateTitle))
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
            Text(.mainWindowCreateAction)
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

// MARK: - CreateDeviceView Preview

#if DEBUG

#Preview("Create Simulator Sheet") {
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

  CreateDeviceView(
    formState: CreateDeviceFormState(
      name: "Preview iPhone",
      runtimeID: runtime.id,
      deviceTypeID: deviceType.id
    ),
    runtimes: [runtime],
    deviceTypes: [deviceType]
  ) { _ in }
}

#endif
