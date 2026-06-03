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

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

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

            Text(subtitle)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)

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
