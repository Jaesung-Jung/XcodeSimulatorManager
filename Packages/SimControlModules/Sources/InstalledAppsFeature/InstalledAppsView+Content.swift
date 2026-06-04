import ComposableArchitecture
import SimControlDomain
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
      } else if store.apps.isEmpty && !store.hasSystemApps {
        EmptyStateView(
          title: "No Matching Apps",
          message: "No installed apps match the current search and filters.",
          systemImage: "line.3.horizontal.decrease.circle"
        )
        .frame(maxWidth: .infinity)
      } else {
        VStack(alignment: .leading, spacing: 10) {
          if !store.userApps.isEmpty {
            AppListSection(title: "User Apps") {
              appList(store.userApps)
            }
          }

          if store.hasSystemApps {
            AppListSection {
              systemAppsHeader
            } content: {
              if !store.systemApps.isEmpty {
                appList(store.systemApps)
              }
            }
          }

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

    private var systemAppsHeader: some View {
      HStack(spacing: 8) {
        Text("System Apps")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Toggle(isOn: Binding(
          get: { store.filters.showsHiddenSystemApps },
          set: { store.send(.showHiddenSystemAppsChanged($0)) }
        )) {
          Text("Show Hidden System Apps")
            .font(.caption)
        }
        .toggleStyle(.checkbox)
      }
    }

    private func appList(_ apps: [InstalledApp]) -> some View {
      InstalledAppList(
        apps: apps,
        selectedAppID: store.selectedAppID,
        pinnedAppIDs: store.filters.pinnedAppIDs,
        onSelection: { id in
          store.send(.selectionChanged(id))
        },
        onPin: { id in
          store.send(.pinButtonTapped(id))
        }
      )
    }
  }
}

extension InstalledAppsView {
  struct AppListSection<Header: View, Content: View>: View {
    let header: Header
    let content: Content

    init(
      @ViewBuilder header: () -> Header,
      @ViewBuilder content: () -> Content
    ) {
      self.header = header()
      self.content = content()
    }

    init(
      title: LocalizedStringKey,
      @ViewBuilder content: () -> Content
    ) where Header == Text {
      self.header = Text(title)
      self.content = content()
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 6) {
        header
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        content
      }
    }
  }
}

// MARK: - InstalledAppsView.InstalledAppsContent Preview

#if DEBUG

#Preview {
  InstalledAppsView.InstalledAppsContent(
    store: Store(initialState: InstalledAppsFeature.State(availability: .loaded)) {
      InstalledAppsFeature()
    }
  )
  .padding(20)
  .frame(width: 420)
}

#endif
