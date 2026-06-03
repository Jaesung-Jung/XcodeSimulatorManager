import MainWindowDisplaySupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension InstalledAppsView {
  struct InstalledAppList: View {
    let apps: [InstalledApp]
    let selectedAppID: String?
    let pinnedAppIDs: Set<String>
    let onSelection: (String) -> Void
    let onPin: (String) -> Void

    var body: some View {
      VStack(spacing: 0) {
        ForEach(apps) { app in
          Button {
            onSelection(app.id)
          } label: {
            AppRow(
              app: app,
              isSelected: app.id == selectedAppID,
              isPinned: pinnedAppIDs.contains(app.id),
              onPin: {
                onPin(app.id)
              }
            )
          }
          .buttonStyle(.plain)

          if app.id != apps.last?.id {
            Divider()
          }
        }
      }
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

extension InstalledAppsView {
  struct AppRow: View {
    let app: InstalledApp
    let isSelected: Bool
    let isPinned: Bool
    let onPin: () -> Void

    private var versionSummary: String? {
      switch (app.version, app.build) {
      case (.some(let version), .some(let build)):
        "Version \(version) (\(build))"
      case (.some(let version), .none):
        "Version \(version)"
      case (.none, .some(let build)):
        "Build \(build)"
      case (.none, .none):
        nil
      }
    }

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: "app")
          .font(.title3)
          .foregroundStyle(.secondary)
          .frame(width: 24)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 3) {
          Text(app.displayName)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)

          Text(app.bundleID)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)

          if let versionSummary {
            Text(versionSummary)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()

        AppRowMetadata(
          app: app,
          isSelected: isSelected,
          isPinned: isPinned,
          onPin: onPin
        )
      }
      .padding(10)
      .contentShape(Rectangle())
      .accessibilityElement(children: .combine)
    }
  }
}

extension InstalledAppsView {
  struct AppRowMetadata: View {
    let app: InstalledApp
    let isSelected: Bool
    let isPinned: Bool
    let onPin: () -> Void

    var body: some View {
      VStack(alignment: .trailing, spacing: 6) {
        HStack(spacing: 8) {
          if isSelected {
            Image(systemName: "checkmark")
              .foregroundStyle(.tint)
              .accessibilityHidden(true)
          }

          Button {
            onPin()
          } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
              .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
          }
          .buttonStyle(.plain)
          .help(isPinned ? "Unpin app" : "Pin app")
        }

        HStack(spacing: 4) {
          if app.isSystemApp {
            StatusBadge(title: "System")
          }

          if !app.appGroups.isEmpty {
            StatusBadge(title: "\(app.appGroups.count) groups")
          }

          if !app.databaseFiles.isEmpty {
            StatusBadge(title: "\(app.databaseFiles.count) db")
          }
        }

        if app.dataContainerSize != nil {
          Text(app.dataContainerSizeTitle)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }
}
