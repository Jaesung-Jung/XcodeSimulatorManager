import MainWindowDisplaySupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension DeviceListView {
  struct Row: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
    let isPinned: Bool
    let onPin: () -> Void

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

    var body: some View {
      HStack(spacing: 8) {
        Circle()
          .fill(device.state.statusTint)
          .frame(width: 6)

        HStack(spacing: 10) {
          Image(systemName: device.symbolName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 4) {
            Text(device.name)
              .font(.subheadline.weight(.medium))
              .lineLimit(1)

            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
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
          }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(device.name), \(subtitle), \(device.state.displayTitle)")
      }
    }
  }
}

// MARK: - DeviceListView.Row Preview

#if DEBUG

#Preview {
  let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: []
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
    dataPath: nil,
    logPath: nil,
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  DeviceListView.Row(
    device: device,
    runtime: runtime,
    deviceType: deviceType,
    isPinned: true,
    onPin: {}
  )
  .padding(20)
  .frame(width: 360)
}

#endif
