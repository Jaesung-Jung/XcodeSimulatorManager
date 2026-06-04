import SwiftUI

extension InstalledAppsView {
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
      .frame(maxWidth: .infinity)
    }
  }
}

// MARK: - InstalledAppsView.ActionButtonLabel Preview

#if DEBUG

#Preview {
  VStack(spacing: 12) {
    InstalledAppsView.ActionButtonLabel(
      title: "Launch",
      systemImage: "play.fill",
      isRunning: false
    )

    InstalledAppsView.DisabledPlaceholder(
      title: "App Inventory Not Loaded",
      message: "Installed app scanning is not available in this phase.",
      systemImage: "app.badge"
    )
  }
  .padding(20)
  .frame(width: 420)
}

#endif

extension InstalledAppsView {
  struct DisabledPlaceholder: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(.subheadline.weight(.medium))

          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(12)
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
      .foregroundStyle(.secondary)
      .accessibilityElement(children: .combine)
    }
  }
}
