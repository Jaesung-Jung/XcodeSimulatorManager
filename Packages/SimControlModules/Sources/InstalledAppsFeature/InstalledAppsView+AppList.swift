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
      LazyVStack(spacing: 0) {
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

// MARK: - InstalledAppList Preview

#if DEBUG

#Preview {
  let app = InstalledApp(
    id: "PREVIEW-DEVICE-1:com.example.preview",
    bundleID: "com.example.preview",
    displayName: "Preview App",
    version: "1.0",
    build: "100",
    deviceID: "PREVIEW-DEVICE-1",
    bundleContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle"),
    dataContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Data"),
    appBundlePath: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle/Preview.app"),
    appGroups: [
      AppGroupContainer(
        id: "group.com.example.preview",
        groupID: "group.com.example.preview",
        path: URL(fileURLWithPath: "/tmp/PreviewApp/Groups/group.com.example.preview")
      )
    ],
    iconPath: nil,
    databaseFiles: [URL(fileURLWithPath: "/tmp/PreviewApp/Data/database.sqlite")],
    dataContainerSize: 24_000_000
  )

  InstalledAppsView.InstalledAppList(
    apps: [app],
    selectedAppID: app.id,
    pinnedAppIDs: [app.id],
    onSelection: { _ in },
    onPin: { _ in }
  )
  .padding(20)
  .frame(width: 420)
}

#endif

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
        AppIconView(iconPath: app.iconPath)

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
