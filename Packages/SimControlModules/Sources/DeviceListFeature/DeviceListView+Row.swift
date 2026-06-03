import MainWindowDisplaySupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension DeviceListView {
  struct Row: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
    let installedAppCount: Int?
    let isPinned: Bool
    let onPin: () -> Void

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: device.symbolName)
          .font(.title3)
          .foregroundStyle(.secondary)
          .frame(width: 24)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          Text(device.name)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)

          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

          HStack(spacing: 6) {
            StatusBadge(
              title: LocalizedStringKey(device.state.displayTitle)
            )
            .tint(device.state.statusTint)

            if let installedAppCount, installedAppCount > 0 {
              StatusBadge(
                title: "\(installedAppCount) apps"
              )
            }
          }
        }

        Spacer(minLength: 8)

        VStack(alignment: .trailing, spacing: 6) {
          Button {
            onPin()
          } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
              .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
          }
          .buttonStyle(.plain)
          .help(isPinned ? "Unpin device" : "Pin device")

          if device.dataPathSize != nil {
            Text(device.dataPathSizeTitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      }
      .padding(.vertical, 5)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(device.name), \(subtitle), \(device.state.displayTitle)")
    }
  }
}
