import ComposableArchitecture
import SimControlSharedUI
import SwiftUI

extension InstalledAppsView {
  struct InstalledAppsContent: View {
    let store: StoreOf<InstalledAppsFeature>

    var body: some View {
      switch store.availability {
      case .notLoaded:
        DisabledPlaceholder(
          title: "App Inventory Not Loaded",
          message: "Installed app scanning is not available in this phase.",
          systemImage: "app.badge"
        )
      case .loaded:
        loadedContent
      }
    }

    @ViewBuilder private var loadedContent: some View {
      if store.allAppsCount == 0 {
        EmptyStateView(
          title: "No Installed Apps",
          message: "Installed app scanning completed and did not find apps for this simulator.",
          systemImage: "app"
        )
        .frame(maxWidth: .infinity)
      } else if store.apps.isEmpty {
        EmptyStateView(
          title: "No Matching Apps",
          message: "No installed apps match the current search and filters.",
          systemImage: "line.3.horizontal.decrease.circle"
        )
        .frame(maxWidth: .infinity)
      } else {
        VStack(alignment: .leading, spacing: 10) {
          InstalledAppList(
            apps: store.apps,
            selectedAppID: store.selectedAppID,
            pinnedAppIDs: store.filters.pinnedAppIDs,
            onSelection: { id in
              store.send(.selectionChanged(id))
            },
            onPin: { id in
              store.send(.pinButtonTapped(id))
            }
          )

          if let selectedApp = store.selectedApp {
            SelectedAppActions(
              app: selectedApp,
              appCommandState: store.appCommandState,
              canLaunch: store.canLaunchSelectedApp,
              canTerminate: store.canTerminateSelectedApp,
              canUninstall: store.canUninstallSelectedApp,
              canResetSandbox: store.canResetSelectedAppSandbox,
              canInstallOnAnotherSimulator: store.canInstallSelectedAppOnAnotherSimulator,
              canUsePaths: store.canUseSelectedAppPaths,
              onLaunch: {
                store.send(.launchButtonTapped(selectedApp.id))
              },
              onTerminate: {
                store.send(.terminateButtonTapped(selectedApp.id))
              },
              onUninstall: {
                store.send(.uninstallButtonTapped(selectedApp.id))
              },
              onResetSandbox: {
                store.send(.resetSandboxButtonTapped(selectedApp.id))
              },
              onInstallOnAnotherSimulator: {
                store.send(.installOnAnotherSimulatorButtonTapped(selectedApp.id))
              },
              onOpenBundleContainer: {
                store.send(.openBundleContainerButtonTapped(selectedApp.id))
              },
              onCopyBundleContainer: {
                store.send(.copyBundleContainerButtonTapped(selectedApp.id))
              },
              onOpenDataContainer: {
                store.send(.openDataContainerButtonTapped(selectedApp.id))
              },
              onCopyDataContainer: {
                store.send(.copyDataContainerButtonTapped(selectedApp.id))
              },
              onCopyBundleID: {
                store.send(.copyBundleIDButtonTapped(selectedApp.id))
              },
              onOpenAppGroup: { groupID in
                store.send(.openAppGroupContainerButtonTapped(selectedApp.id, groupID))
              },
              onCopyAppGroup: { groupID in
                store.send(.copyAppGroupContainerButtonTapped(selectedApp.id, groupID))
              }
            )
          }
        }
      }
    }
  }
}
