import MainWindowDisplaySupport
import MainWindowFeatureSupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

// MARK: - DeviceDetailView.Header

extension DeviceDetailView {
  struct Header: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
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

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: device.symbolName)
            .font(.system(size: 30, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(width: 36)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
              Text(device.name)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

              StatusBadge(
                title: LocalizedStringKey(device.state.displayTitle)
              )
              .tint(device.state.statusTint)
            }

            Text(device.udid)
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
              .lineLimit(1)
              .truncationMode(.middle)
          }

          Spacer()

          DeviceCommandControls(
            device: device,
            pairSummary: pairSummary,
            deviceCommandState: deviceCommandState,
            appCommandState: appCommandState,
            isOpeningSimulatorApp: isOpeningSimulatorApp,
            onBoot: onBoot,
            onShutdown: onShutdown,
            onOpenSimulatorApp: onOpenSimulatorApp,
            onRename: onRename,
            onErase: onErase,
            onDelete: onDelete,
            onUnpair: onUnpair,
            onOpenDataFolder: onOpenDataFolder,
            onCopyDataPath: onCopyDataPath,
            onOpenLogFolder: onOpenLogFolder,
            onCopyLogPath: onCopyLogPath,
            onCopyUDID: onCopyUDID,
            onCopyRuntimeIdentifier: onCopyRuntimeIdentifier,
            onCopyDeviceTypeIdentifier: onCopyDeviceTypeIdentifier
          )
        }
      }
      .padding(.bottom, 2)
    }
  }
}

// MARK: - DeviceDetailView.Header Preview

#if DEBUG

#Preview {
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
  let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: runtime.id,
    deviceTypeID: deviceType.id,
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/tmp/PreviewDevice/data"),
    logPath: URL(fileURLWithPath: "/tmp/PreviewDevice/logs"),
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  DeviceDetailView.Header(
    device: device,
    runtime: runtime,
    deviceType: deviceType,
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
  .frame(width: 720)
}

#endif
