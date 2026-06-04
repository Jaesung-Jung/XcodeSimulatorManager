import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

// MARK: - DeviceDetailView.DeviceCommandControls

extension DeviceDetailView {
  struct DeviceCommandControls: View {
    let device: SimulatorDevice
    let pairSummary: DeviceDetailFeature.DevicePairSummary?
    let deviceCommandState: DeviceCommandState?
    let appCommandState: AppCommandState?
    let isOpeningSimulatorApp: Bool
    let onBoot: () -> Void
    let onShutdown: () -> Void
    let onOpenSimulatorApp: () -> Void
    let onRename: () -> Void
    let onErase: () -> Void
    let onDelete: () -> Void
    let onUnpair: (String) -> Void
    let onOpenDataFolder: () -> Void
    let onCopyDataPath: () -> Void
    let onOpenLogFolder: () -> Void
    let onCopyLogPath: () -> Void
    let onCopyUDID: () -> Void
    let onCopyRuntimeIdentifier: () -> Void
    let onCopyDeviceTypeIdentifier: () -> Void

    private var canBoot: Bool { device.isAvailable && device.state == .shutdown }
    private var canShutdown: Bool { device.isAvailable && device.state == .booted }
    private var isLifecycleActionRunning: Bool { deviceCommandState != nil || appCommandState != nil }
    private var isBootRunning: Bool { deviceCommandState == DeviceCommandState(command: .boot, deviceID: device.id) }
    private var isShutdownRunning: Bool { deviceCommandState == DeviceCommandState(command: .shutdown, deviceID: device.id) }

    var body: some View {
      HStack(spacing: 8) {
        if canBoot {
          Button {
            onBoot()
          } label: {
            ActionButtonLabel(
              title: isBootRunning ? "Booting" : "Boot",
              systemImage: "power",
              isRunning: isBootRunning
            )
          }
          .disabled(isLifecycleActionRunning)
          .help("Boot selected simulator")
        }

        if canShutdown {
          Button {
            onShutdown()
          } label: {
            ActionButtonLabel(
              title: isShutdownRunning ? "Shutting Down" : "Shutdown",
              systemImage: "power",
              isRunning: isShutdownRunning
            )
          }
          .disabled(isLifecycleActionRunning)
          .help("Shut down selected simulator")
        }

        Button {
          onOpenSimulatorApp()
        } label: {
          ActionButtonLabel(
            title: isOpeningSimulatorApp ? "Opening" : "Open",
            systemImage: "play.rectangle",
            isRunning: isOpeningSimulatorApp
          )
        }
        .disabled(isOpeningSimulatorApp)
        .help("Open Simulator.app")

        Menu {
          Button {
            onRename()
          } label: {
            Label("Rename", systemImage: "pencil")
          }
          .disabled(isLifecycleActionRunning)

          Button(role: .destructive) {
            onErase()
          } label: {
            Label("Erase...", systemImage: "eraser")
          }
          .disabled(isLifecycleActionRunning || !device.isAvailable)

          Button(role: .destructive) {
            onDelete()
          } label: {
            Label("Delete...", systemImage: "trash")
          }
          .disabled(isLifecycleActionRunning)

          if let pairSummary {
            Divider()

            Button(role: .destructive) {
              onUnpair(pairSummary.id)
            } label: {
              Label("Unpair...", systemImage: "link.badge.minus")
            }
            .disabled(isLifecycleActionRunning)
          }

          Divider()

          Button {
            onOpenDataFolder()
          } label: {
            Label("Open Data Folder", systemImage: "folder")
          }
          .disabled(device.dataPath == nil)

          Button {
            onCopyDataPath()
          } label: {
            Label("Copy Data Path", systemImage: "doc.on.doc")
          }
          .disabled(device.dataPath == nil)

          Button {
            onOpenLogFolder()
          } label: {
            Label("Open Log Folder", systemImage: "folder")
          }
          .disabled(device.logPath == nil)

          Button {
            onCopyLogPath()
          } label: {
            Label("Copy Log Path", systemImage: "doc.on.doc")
          }
          .disabled(device.logPath == nil)

          Divider()

          Button {
            onCopyUDID()
          } label: {
            Label("Copy UDID", systemImage: "doc.on.doc")
          }

          Button {
            onCopyRuntimeIdentifier()
          } label: {
            Label("Copy Runtime Identifier", systemImage: "doc.on.doc")
          }

          Button {
            onCopyDeviceTypeIdentifier()
          } label: {
            Label("Copy Device Type Identifier", systemImage: "doc.on.doc")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .accessibilityLabel("More device actions")
        }
        .disabled(isLifecycleActionRunning)
        .help("More device actions")
      }
      .buttonStyle(.bordered)
    }
  }
}

// MARK: - DeviceCommandControls Preview

#if DEBUG

#Preview {
  let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    deviceTypeID: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/tmp/PreviewDevice/data"),
    logPath: URL(fileURLWithPath: "/tmp/PreviewDevice/logs"),
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  DeviceDetailView.DeviceCommandControls(
    device: device,
    pairSummary: nil,
    deviceCommandState: nil,
    appCommandState: nil,
    isOpeningSimulatorApp: false,
    onBoot: {},
    onShutdown: {},
    onOpenSimulatorApp: {},
    onRename: {},
    onErase: {},
    onDelete: {},
    onUnpair: { _ in },
    onOpenDataFolder: {},
    onCopyDataPath: {},
    onOpenLogFolder: {},
    onCopyLogPath: {},
    onCopyUDID: {},
    onCopyRuntimeIdentifier: {},
    onCopyDeviceTypeIdentifier: {}
  )
  .padding(20)
}

#endif
