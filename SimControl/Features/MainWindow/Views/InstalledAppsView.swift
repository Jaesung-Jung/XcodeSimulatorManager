import ComposableArchitecture
import SwiftUI

struct InstalledAppsView: View {
  let store: StoreOf<InstalledAppsFeature>

  private var appSystemFilter: Binding<SimulatorFilters.AppSystemFilter> {
    Binding(
      get: { store.filters.appSystemFilter },
      set: { store.send(.appSystemFilterChanged($0)) }
    )
  }

  private var appGroupFilter: Binding<SimulatorFilters.PresenceFilter> {
    Binding(
      get: { store.filters.appGroupFilter },
      set: { store.send(.appGroupFilterChanged($0)) }
    )
  }

  private var appDatabaseFilter: Binding<SimulatorFilters.PresenceFilter> {
    Binding(
      get: { store.filters.appDatabaseFilter },
      set: { store.send(.appDatabaseFilterChanged($0)) }
    )
  }

  private var appSort: Binding<SimulatorFilters.AppSort> {
    Binding(
      get: { store.filters.appSort },
      set: { store.send(.appSortChanged($0)) }
    )
  }

  private var appSortDirection: Binding<SimulatorFilters.SortDirection> {
    Binding(
      get: { store.filters.appSortDirection },
      set: { store.send(.appSortDirectionChanged($0)) }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        SectionHeader(title: "Installed Apps", systemImage: "app")

        Spacer()

        if store.availability == .loaded {
          Text("\(store.apps.count) of \(store.allAppsCount)")
            .font(.caption)
            .foregroundStyle(.secondary)

          AppFilterMenu(
            systemFilter: appSystemFilter,
            appGroupFilter: appGroupFilter,
            databaseFilter: appDatabaseFilter
          )

          AppSortMenu(
            sort: appSort,
            direction: appSortDirection
          )
        }
      }

      if store.filters.hasActiveAppFilters {
        ActiveAppFilters(
          filters: store.filters,
          onClear: {
            store.send(.clearAppFiltersButtonTapped)
          }
        )
      }

      switch store.availability {
      case .notLoaded:
        DisabledPlaceholder(
          title: "App Inventory Not Loaded",
          message: "Installed app scanning is not available in this phase.",
          systemImage: "app.badge"
        )
      case .loaded:
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
            VStack(spacing: 0) {
              ForEach(store.apps) { app in
                Button {
                  store.send(.selectionChanged(app.id))
                } label: {
                  AppRow(
                    app: app,
                    isSelected: app.id == store.selectedAppID,
                    isPinned: store.filters.pinnedAppIDs.contains(app.id),
                    onPin: {
                      store.send(.pinButtonTapped(app.id))
                    }
                  )
                }
                .buttonStyle(.plain)

                if app.id != store.apps.last?.id {
                  Divider()
                }
              }
            }
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

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
}

extension InstalledAppsView {
  private struct AppFilterMenu: View {
    @Binding var systemFilter: SimulatorFilters.AppSystemFilter
    @Binding var appGroupFilter: SimulatorFilters.PresenceFilter
    @Binding var databaseFilter: SimulatorFilters.PresenceFilter

    var body: some View {
      Menu {
        Picker("App Type", selection: $systemFilter) {
          Text(SimulatorFilters.AppSystemFilter.user.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.user)
          Text(SimulatorFilters.AppSystemFilter.system.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.system)
          Text(SimulatorFilters.AppSystemFilter.all.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.all)
        }

        Picker("App Groups", selection: $appGroupFilter) {
          Text(SimulatorFilters.PresenceFilter.all.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.all)
          Text(SimulatorFilters.PresenceFilter.present.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.present)
          Text(SimulatorFilters.PresenceFilter.absent.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.absent)
        }

        Picker("Databases", selection: $databaseFilter) {
          Text(SimulatorFilters.PresenceFilter.all.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.all)
          Text(SimulatorFilters.PresenceFilter.present.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.present)
          Text(SimulatorFilters.PresenceFilter.absent.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.absent)
        }
      } label: {
        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
      }
      .help("Filter installed apps")
    }
  }
}

extension InstalledAppsView {
  private struct AppSortMenu: View {
    @Binding var sort: SimulatorFilters.AppSort
    @Binding var direction: SimulatorFilters.SortDirection

    var body: some View {
      Menu {
        Picker("Sort By", selection: $sort) {
          Text(SimulatorFilters.AppSort.name.displayTitle)
            .tag(SimulatorFilters.AppSort.name)
          Text(SimulatorFilters.AppSort.bundleID.displayTitle)
            .tag(SimulatorFilters.AppSort.bundleID)
          Text(SimulatorFilters.AppSort.version.displayTitle)
            .tag(SimulatorFilters.AppSort.version)
          Text(SimulatorFilters.AppSort.dataSize.displayTitle)
            .tag(SimulatorFilters.AppSort.dataSize)
        }

        Divider()

        Picker("Direction", selection: $direction) {
          Text(SimulatorFilters.SortDirection.ascending.displayTitle)
            .tag(SimulatorFilters.SortDirection.ascending)
          Text(SimulatorFilters.SortDirection.descending.displayTitle)
            .tag(SimulatorFilters.SortDirection.descending)
        }
      } label: {
        Label("Sort", systemImage: "arrow.up.arrow.down")
      }
      .help("Sort installed apps")
    }
  }
}

extension InstalledAppsView {
  private struct ActiveAppFilters: View {
    let filters: SimulatorFilters
    let onClear: () -> Void

    var body: some View {
      HStack(spacing: 6) {
        if filters.appSystemFilter != .user {
          FilterChip(title: filters.appSystemFilter.displayTitle)
        }

        if filters.appGroupFilter != .all {
          FilterChip(title: filters.appGroupFilter.appGroupDisplayTitle)
        }

        if filters.appDatabaseFilter != .all {
          FilterChip(title: filters.appDatabaseFilter.databaseDisplayTitle)
        }

        Spacer(minLength: 4)

        Button("Clear") {
          onClear()
        }
        .buttonStyle(.plain)
        .font(.caption)
      }
    }
  }
}

extension InstalledAppsView {
  private struct FilterChip: View {
    let title: String

    var body: some View {
      Text(title)
        .font(.caption)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.45), in: Capsule())
    }
  }
}

extension InstalledAppsView {
  private struct AppRow: View {
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
      .padding(10)
      .contentShape(Rectangle())
      .accessibilityElement(children: .combine)
    }
  }
}

extension InstalledAppsView {
  private struct SelectedAppActions: View {
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

          Menu {
            Button {
              onOpenBundleContainer()
            } label: {
              Label("Open Bundle Container", systemImage: "folder")
            }

            Button {
              onCopyBundleContainer()
            } label: {
              Label("Copy Bundle Container Path", systemImage: "doc.on.doc")
            }

            Button {
              onOpenDataContainer()
            } label: {
              Label("Open Data Container", systemImage: "folder")
            }

            Button {
              onCopyDataContainer()
            } label: {
              Label("Copy Data Container Path", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
              onCopyBundleID()
            } label: {
              Label("Copy Bundle Identifier", systemImage: "doc.on.doc")
            }

            if !app.appGroups.isEmpty {
              Divider()

              ForEach(app.appGroups) { appGroup in
                Menu {
                  Button {
                    onOpenAppGroup(appGroup.groupID)
                  } label: {
                    Label("Open Container", systemImage: "folder")
                  }

                  Button {
                    onCopyAppGroup(appGroup.groupID)
                  } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                  }
                } label: {
                  Label(appGroup.groupID, systemImage: "person.2.crop.square.stack")
                }
              }
            }
          } label: {
            ActionButtonLabel(
              title: "Paths",
              systemImage: "folder",
              isRunning: false
            )
          }
          .disabled(!canUsePaths)
        }
        .buttonStyle(.bordered)
      }
      .padding(10)
      .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    private func isRunning(_ command: AppCommand) -> Bool {
      appCommandState?.command == command && appCommandState?.appID == app.id
    }
  }
}

extension InstalledAppsView {
  private struct ActionButtonLabel: View {
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

extension InstalledAppsView {
  private struct DisabledPlaceholder: View {
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

// MARK: - InstalledAppsView Preview

#if DEBUG

#Preview {
  InstalledAppsView(
    store: Store(
      initialState: InstalledAppsFeature.State(
        apps: [MainWindowPreviewFixtures.app],
        availability: .loaded
      )
    ) {
      InstalledAppsFeature()
    }
  )
  .padding(20)
}

#endif
