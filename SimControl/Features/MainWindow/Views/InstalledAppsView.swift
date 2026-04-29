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
