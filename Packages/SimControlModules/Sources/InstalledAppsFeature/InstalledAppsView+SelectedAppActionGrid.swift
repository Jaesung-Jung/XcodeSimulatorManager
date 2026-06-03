import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

extension InstalledAppsView {
  struct SelectedAppActionGrid: View {
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
      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 132), spacing: 8)
        ],
        alignment: .leading,
        spacing: 8
      ) {
        Button {
          onLaunch()
        } label: {
          ActionButtonLabel(
            title: isRunning(.launch) ? "Launching" : "Launch",
            systemImage: "play.fill",
            isRunning: isRunning(.launch)
          )
        }
        .disabled(!canLaunch)

        Button {
          onTerminate()
        } label: {
          ActionButtonLabel(
            title: isRunning(.terminate) ? "Terminating" : "Terminate",
            systemImage: "stop.fill",
            isRunning: isRunning(.terminate)
          )
        }
        .disabled(!canTerminate)

        Button(role: .destructive) {
          onUninstall()
        } label: {
          ActionButtonLabel(
            title: isRunning(.uninstall) ? "Uninstalling" : "Uninstall...",
            systemImage: "trash",
            isRunning: isRunning(.uninstall)
          )
        }
        .disabled(!canUninstall)

        Button(role: .destructive) {
          onResetSandbox()
        } label: {
          ActionButtonLabel(
            title: isRunning(.resetSandbox) ? "Resetting" : "Reset Sandbox...",
            systemImage: "folder.badge.minus",
            isRunning: isRunning(.resetSandbox)
          )
        }
        .disabled(!canResetSandbox)

        Button {
          onInstallOnAnotherSimulator()
        } label: {
          ActionButtonLabel(
            title: isRunning(.installOnSimulator) ? "Installing" : "Install...",
            systemImage: "square.and.arrow.down",
            isRunning: isRunning(.installOnSimulator)
          )
        }
        .disabled(!canInstallOnAnotherSimulator)

        SelectedAppPathsMenu(
          app: app,
          canUsePaths: canUsePaths,
          onOpenBundleContainer: onOpenBundleContainer,
          onCopyBundleContainer: onCopyBundleContainer,
          onOpenDataContainer: onOpenDataContainer,
          onCopyDataContainer: onCopyDataContainer,
          onCopyBundleID: onCopyBundleID,
          onOpenAppGroup: onOpenAppGroup,
          onCopyAppGroup: onCopyAppGroup
        )
      }
      .buttonStyle(.bordered)
    }

    private func isRunning(_ command: AppCommand) -> Bool {
      appCommandState?.command == command && appCommandState?.appID == app.id
    }
  }
}
