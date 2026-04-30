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

  private var filters: SimulatorFilters {
    store.workspace.filters
  }

  private var runtimeByID: [String: SimulatorRuntime] {
    Dictionary(uniqueKeysWithValues: (snapshot?.runtimes ?? []).map { ($0.id, $0) })
  }

  private var pinnedDevices: [SimulatorDevice] {
    devices.filter { filters.pinnedDeviceIDs.contains($0.id) }
  }

  private var installedAppsByID: [String: InstalledApp] {
    Dictionary(
      uniqueKeysWithValues: (snapshot?.installedAppsByDeviceID.values.flatMap { $0 } ?? []).map {
        ($0.id, $0)
      }
    )
  }

  private var pinnedApps: [InstalledApp] {
    installedAppsByID.values
      .filter { filters.pinnedAppIDs.contains($0.id) }
      .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
  }

  private var recentApps: [InstalledApp] {
    filters.recentAppIDs.compactMap { installedAppsByID[$0] }
  }

  var body: some View {
    if !pinnedDevices.isEmpty {
      Section("Pinned Devices") {
        ForEach(pinnedDevices) { device in
          DeviceButton(
            device: device,
            title: deviceTitle(for: device),
            onSelect: {
              selectDevice(device)
            }
          )
        }
      }
    }

    if !pinnedApps.isEmpty {
      Section("Pinned Apps") {
        ForEach(pinnedApps) { app in
          AppButton(app: app) {
            selectApp(app)
          }
        }
      }
    }

    if !recentApps.isEmpty {
      Section("Recent Apps") {
        ForEach(recentApps) { app in
          AppButton(app: app) {
            selectApp(app)
          }
        }
      }
    }

    Section("Devices") {
      if snapshot == nil {
        Text("No cached devices")
          .foregroundStyle(.secondary)
      } else if devices.isEmpty {
        Text("No devices found")
          .foregroundStyle(.secondary)
      } else {
        ForEach(devices) { device in
          DeviceButton(
            device: device,
            title: deviceTitle(for: device),
            onSelect: {
              selectDevice(device)
            }
          )
        }
      }
    }
  }

  private func selectDevice(_ device: SimulatorDevice) {
    store.send(.workspace(.deviceList(.selectionChanged(device.id))))
    openMainWindow()
  }

  private func selectApp(_ app: InstalledApp) {
    store.send(.workspace(.deviceList(.selectionChanged(app.deviceID))))
    store.send(.workspace(.deviceDetail(.installedApps(.selectionChanged(app.id)))))
    openMainWindow()
  }

  private func deviceTitle(for device: SimulatorDevice) -> String {
    let runtimeName = runtimeByID[device.runtimeID]?.name ?? device.runtimeID
    return "\(device.name) - \(runtimeName) - \(device.state.displayTitle)"
  }
}

extension MenuBarDeviceSection {
  private struct DeviceButton: View {
    let device: SimulatorDevice
    let title: String
    let onSelect: () -> Void

    var body: some View {
      Button {
        onSelect()
      } label: {
        Label(title, systemImage: device.platform.symbolName)
      }
    }
  }
}

extension MenuBarDeviceSection {
  private struct AppButton: View {
    let app: InstalledApp
    let onSelect: () -> Void

    var body: some View {
      Button {
        onSelect()
      } label: {
        Label(
          "\(app.displayName) - \(app.bundleID)",
          systemImage: "app"
        )
      }
    }
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
