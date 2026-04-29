import ComposableArchitecture
import SwiftUI

struct InstalledAppsView: View {
  let store: StoreOf<InstalledAppsFeature>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader(title: "Installed Apps", systemImage: "app")

      switch store.availability {
      case .notLoaded:
        DisabledPlaceholder(
          title: "App Inventory Not Loaded",
          message: "Installed app scanning is not available in this phase.",
          systemImage: "app.badge"
        )
      case .loaded:
        if store.apps.isEmpty {
          EmptyStateView(
            title: "No Installed Apps",
            message: "Installed app scanning completed and did not find apps for this simulator.",
            systemImage: "app"
          )
          .frame(maxWidth: .infinity)
        } else {
          VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
              ForEach(store.apps) { app in
                Button {
                  store.send(.selectionChanged(app.id))
                } label: {
                  AppRow(app: app, isSelected: app.id == store.selectedAppID)
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
  private struct AppRow: View {
    let app: InstalledApp
    let isSelected: Bool

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

        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
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
    let onLaunch: () -> Void
    let onTerminate: () -> Void
    let onUninstall: () -> Void
    let onResetSandbox: () -> Void
    let onInstallOnAnotherSimulator: () -> Void

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
            .fixedSize(horizontal: false, vertical: true)
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
