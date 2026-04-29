import ComposableArchitecture
import SwiftUI

@MainActor
struct MenuBarDeviceSection: View {
  let store: StoreOf<MainWindowFeature>
  let openMainWindow: () -> Void

  private var snapshot: SimulatorSnapshot? {
    store.workspace.snapshot
  }

  private var devices: [SimulatorDevice] {
    snapshot?.devices ?? []
  }

  private var runtimeByID: [String: SimulatorRuntime] {
    Dictionary(uniqueKeysWithValues: (snapshot?.runtimes ?? []).map { ($0.id, $0) })
  }

  var body: some View {
    Section("Devices") {
      if snapshot == nil {
        Text("No cached devices")
          .foregroundStyle(.secondary)
      } else if devices.isEmpty {
        Text("No devices found")
          .foregroundStyle(.secondary)
      } else {
        ForEach(devices) { device in
          Button {
            store.send(.workspace(.deviceList(.selectionChanged(device.id))))
            openMainWindow()
          } label: {
            Label(
              deviceTitle(for: device),
              systemImage: device.platform.symbolName
            )
          }
        }
      }
    }
  }

  private func deviceTitle(for device: SimulatorDevice) -> String {
    let runtimeName = runtimeByID[device.runtimeID]?.name ?? device.runtimeID
    return "\(device.name) - \(runtimeName) - \(device.state.displayTitle)"
  }
}

// MARK: - MenuBarDeviceSection Preview

#if DEBUG

#Preview {
  MenuBarDeviceSection(
    store: .mainWindowPreview,
    openMainWindow: {}
  )
}

#endif
