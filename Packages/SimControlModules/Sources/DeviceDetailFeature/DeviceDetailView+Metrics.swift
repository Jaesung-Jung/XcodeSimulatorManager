import SimControlDomain
import SwiftUI

// MARK: - DeviceDetailView.MetricsGrid

extension DeviceDetailView {
  struct MetricsGrid: View {
    let device: SimulatorDevice
    let runtimeName: String
    let appMetricValue: String

    var body: some View {
      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 150), spacing: 10)
        ],
        alignment: .leading,
        spacing: 10
      ) {
        MetricTile(
          title: "Platform",
          value: device.platform.displayTitle,
          systemImage: device.symbolName
        )
        MetricTile(
          title: "Runtime",
          value: runtimeName,
          systemImage: "shippingbox"
        )
        MetricTile(
          title: "Apps",
          value: appMetricValue,
          systemImage: "app"
        )
        MetricTile(
          title: "Data Size",
          value: device.dataPathSizeTitle,
          systemImage: "internaldrive"
        )
        MetricTile(
          title: "Availability",
          value: device.availabilityTitle,
          systemImage: device.isAvailable ? "checkmark.circle" : "exclamationmark.triangle"
        )
        MetricTile(
          title: "Last Booted",
          value: device.lastBootedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown",
          systemImage: "clock"
        )
      }
    }
  }
}

// MARK: - DeviceDetailView.MetricsGrid Preview

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
    dataPath: nil,
    logPath: nil,
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  DeviceDetailView.MetricsGrid(
    device: device,
    runtimeName: "iOS 26.4",
    appMetricValue: "3"
  )
  .padding(20)
  .frame(width: 560)
}

#endif

// MARK: - DeviceDetailView.MetricTile

extension DeviceDetailView {
  struct MetricTile: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: systemImage)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Text(value)
          .font(.subheadline.weight(.medium))
          .lineLimit(2)
          .truncationMode(.middle)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(10)
      .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .combine)
    }
  }
}
