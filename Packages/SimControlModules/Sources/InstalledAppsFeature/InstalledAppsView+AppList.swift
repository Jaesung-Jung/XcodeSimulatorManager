import MainWindowDisplaySupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension InstalledAppsView {
  struct InstalledAppList<SelectedAppActions: View>: View {
    let apps: [InstalledApp]
    var platform: SimulatorPlatform? = nil
    var deviceTypeID: String? = nil
    let selectedAppID: String?
    let pinnedAppIDs: Set<String>
    let selectedAppActions: (InstalledApp) -> SelectedAppActions
    let onSelection: (String?) -> Void
    let onPin: (String) -> Void

    static func selectionID(for appID: String, selectedAppID: String?) -> String? {
      appID == selectedAppID ? nil : appID
    }

    var body: some View {
      VStack(spacing: 0) {
        ForEach(apps) { app in
          Button {
            onSelection(Self.selectionID(for: app.id, selectedAppID: selectedAppID))
          } label: {
            AppRow(
              app: app,
              platform: platform,
              deviceTypeID: deviceTypeID,
              isSelected: app.id == selectedAppID,
              isPinned: pinnedAppIDs.contains(app.id),
              onPin: {
                onPin(app.id)
              }
            )
          }
          .buttonStyle(.plain)

          if app.id == selectedAppID {
            selectedAppActions(app)
              .padding(.horizontal, 10)
              .padding(.bottom, 10)
          }

          if app.id != apps.last?.id {
            Divider()
          }
        }
      }
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

extension InstalledAppsView.InstalledAppList where SelectedAppActions == EmptyView {
  init(
    apps: [InstalledApp],
    platform: SimulatorPlatform? = nil,
    deviceTypeID: String? = nil,
    selectedAppID: String?,
    pinnedAppIDs: Set<String>,
    onSelection: @escaping (String?) -> Void,
    onPin: @escaping (String) -> Void
  ) {
    self.apps = apps
    self.platform = platform
    self.deviceTypeID = deviceTypeID
    self.selectedAppID = selectedAppID
    self.pinnedAppIDs = pinnedAppIDs
    self.selectedAppActions = { _ in EmptyView() }
    self.onSelection = onSelection
    self.onPin = onPin
  }
}

extension InstalledAppsView {
  struct AppRow: View {
    let app: InstalledApp
    var platform: SimulatorPlatform? = nil
    var deviceTypeID: String? = nil
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
        AppIconView(
          iconPath: app.iconPath,
          appBundlePath: app.appBundlePath,
          bundleID: app.bundleID,
          displayName: app.displayName,
          platform: platform,
          deviceTypeID: deviceTypeID
        )

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
          isPinned: isPinned,
          onPin: onPin
        )
      }
      .padding(10)
      .contentShape(Rectangle())
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(.quaternary)
          .padding(4)
          .opacity(isSelected ? 1 : 0)
      }
      .accessibilityElement(children: .combine)
    }
  }
}

extension InstalledAppsView {
  struct AppRowMetadata: View {
    let app: InstalledApp
    let isPinned: Bool
    let onPin: () -> Void

    static func bookmarkIconName(isBookmarked: Bool) -> String {
      isBookmarked ? "bookmark.fill" : "bookmark"
    }

    static func bookmarkHelpTitle(isBookmarked: Bool) -> String {
      isBookmarked ? "Remove app bookmark" : "Bookmark app"
    }

    var body: some View {
      VStack(alignment: .trailing, spacing: 6) {
        HStack(spacing: 8) {
          Button {
            onPin()
          } label: {
            Image(systemName: Self.bookmarkIconName(isBookmarked: isPinned))
              .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
          }
          .buttonStyle(.plain)
          .help(Self.bookmarkHelpTitle(isBookmarked: isPinned))
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
