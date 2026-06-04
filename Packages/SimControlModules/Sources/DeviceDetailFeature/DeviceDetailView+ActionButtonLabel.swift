import SwiftUI

// MARK: - DeviceDetailView.ActionButtonLabel

extension DeviceDetailView {
  struct ActionButtonLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let isRunning: Bool

    var body: some View {
      HStack(spacing: 6) {
        if isRunning {
          ProgressView()
            .controlSize(.small)
            .frame(width: 14, height: 14)
        } else {
          Image(systemName: systemImage)
            .accessibilityHidden(true)
        }

        Text(title)
          .lineLimit(1)
      }
      .frame(minWidth: 78)
    }
  }
}

// MARK: - DeviceDetailView.ActionButtonLabel Preview

#if DEBUG

#Preview {
  VStack(spacing: 12) {
    DeviceDetailView.ActionButtonLabel(
      title: "Boot",
      systemImage: "power",
      isRunning: false
    )

    DeviceDetailView.ActionButtonLabel(
      title: "Booting",
      systemImage: "power",
      isRunning: true
    )
  }
  .padding(20)
}

#endif
