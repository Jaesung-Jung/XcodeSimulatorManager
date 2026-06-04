import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

extension InstalledAppsView {
  struct SelectedAppActions: View {
    let app: InstalledApp
    let appCommandState: AppCommandState?
    let canLaunch: Bool
    let canTerminate: Bool
    let canUninstall: Bool
    let canResetSandbox: Bool
    let canInstallOnAnotherSimulator: Bool
    let canUsePaths: Bool
    let onLaunch: () -> Void
    let onTerminate: () -> Void
    let onUninstall: () -> Void
    let onResetSandbox: () -> Void
    let onInstallOnAnotherSimulator: () -> Void
    let onOpenBundleContainer: () -> Void
    let onCopyBundleContainer: () -> Void
    let onOpenDataContainer: () -> Void
    let onCopyDataContainer: () -> Void
    let onCopyBundleID: () -> Void
    let onOpenAppGroup: (String) -> Void
    let onCopyAppGroup: (String) -> Void

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        SelectedAppHeader(app: app)

        SelectedAppActionGrid(
          app: app,
          appCommandState: appCommandState,
          canLaunch: canLaunch,
          canTerminate: canTerminate,
          canUninstall: canUninstall,
          canResetSandbox: canResetSandbox,
          canInstallOnAnotherSimulator: canInstallOnAnotherSimulator,
          canUsePaths: canUsePaths,
          onLaunch: onLaunch,
          onTerminate: onTerminate,
          onUninstall: onUninstall,
          onResetSandbox: onResetSandbox,
          onInstallOnAnotherSimulator: onInstallOnAnotherSimulator,
          onOpenBundleContainer: onOpenBundleContainer,
          onCopyBundleContainer: onCopyBundleContainer,
          onOpenDataContainer: onOpenDataContainer,
          onCopyDataContainer: onCopyDataContainer,
          onCopyBundleID: onCopyBundleID,
          onOpenAppGroup: onOpenAppGroup,
          onCopyAppGroup: onCopyAppGroup
        )
      }
      .padding(10)
      .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

// MARK: - InstalledAppsView.SelectedAppActions Preview

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
    appGroups: [],
    iconPath: nil
  )

  InstalledAppsView.SelectedAppActions(
    app: app,
    appCommandState: nil,
    canLaunch: true,
    canTerminate: true,
    canUninstall: true,
    canResetSandbox: true,
    canInstallOnAnotherSimulator: true,
    canUsePaths: true,
    onLaunch: {},
    onTerminate: {},
    onUninstall: {},
    onResetSandbox: {},
    onInstallOnAnotherSimulator: {},
    onOpenBundleContainer: {},
    onCopyBundleContainer: {},
    onOpenDataContainer: {},
    onCopyDataContainer: {},
    onCopyBundleID: {},
    onOpenAppGroup: { _ in },
    onCopyAppGroup: { _ in }
  )
  .padding(20)
  .frame(width: 560)
}

#endif

extension InstalledAppsView {
  struct SelectedAppHeader: View {
    let app: InstalledApp

    var body: some View {
      HStack(spacing: 8) {
        Image(systemName: "app")
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 2) {
          Text(app.displayName)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)

          Text(app.bundleID)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Spacer()
      }
    }
  }
}
