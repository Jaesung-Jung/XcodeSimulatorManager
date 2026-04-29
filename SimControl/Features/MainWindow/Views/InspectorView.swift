import ComposableArchitecture
import SwiftUI

struct InspectorView: View {
  let store: StoreOf<InspectorFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        if let device = store.device {
          InspectorSection("Device") {
            FieldRow(title: "Name", value: device.name)
            FieldRow(title: "UDID", value: device.udid)
            FieldRow(title: "State", value: device.state.displayTitle)
            FieldRow(title: "Runtime", value: store.runtime?.name ?? device.runtimeID)
            FieldRow(title: "Device Type", value: store.deviceType?.name ?? device.deviceTypeID)
            FieldRow(
              title: "Availability",
              value: device.availabilityTitle
            )
          }

          Divider()

          InspectorSection("Folders") {
            FieldRow(title: "Data", value: device.dataPath?.path)
            FieldRow(title: "Logs", value: device.logPath?.path)
          }
        } else {
          EmptyStateView(
            title: "No Selection",
            message: "Select a simulator to inspect identifiers, folders, environment, and warnings.",
            systemImage: "info.circle"
          )
          .frame(maxWidth: .infinity)
        }

        if let selectedApp = store.selectedApp {
          Divider()

          InspectorSection("Selected App") {
            FieldRow(title: "Name", value: selectedApp.displayName)
            FieldRow(title: "Bundle ID", value: selectedApp.bundleID)
            FieldRow(title: "Version", value: selectedApp.version)
            FieldRow(title: "Build", value: selectedApp.build)
            FieldRow(title: "Bundle Container", value: selectedApp.bundleContainer?.path)
            FieldRow(title: "Data Container", value: selectedApp.dataContainer?.path)
          }

          if !selectedApp.appGroups.isEmpty {
            Divider()

            InspectorSection("App Groups") {
              ForEach(selectedApp.appGroups) { appGroup in
                FieldRow(
                  title: LocalizedStringKey(appGroup.groupID),
                  value: appGroup.path.path
                )
              }
            }
          }
        }

        Divider()

        InspectorSection("Environment") {
          FieldRow(
            title: "Xcode Path",
            value: store.snapshot?.xcode.developerPath?.path
          )
          FieldRow(title: "Xcode Version", value: store.snapshot?.xcode.version)
          FieldRow(
            title: "Last Refresh",
            value: store.snapshot?.generatedAt.formatted(date: .abbreviated, time: .shortened)
          )
        }

        if let snapshot = store.snapshot, !snapshot.warnings.isEmpty {
          Divider()

          InspectorSection("Warnings") {
            ForEach(snapshot.warnings) { warning in
              WarningRow(warning: warning)
            }
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .background(.background)
  }
}

extension InspectorView {
  private struct InspectorSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
      self.title = title
      self.content = content()
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
          .font(.headline)

        VStack(alignment: .leading, spacing: 10) {
          content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

extension InspectorView {
  private struct FieldRow: View {
    let title: LocalizedStringKey
    let value: String?
    let placeholder: LocalizedStringKey

    private var displayValue: String? {
      guard let value, !value.isEmpty else {
        return nil
      }
      return value
    }

    init(
      title: LocalizedStringKey,
      value: String?,
      placeholder: LocalizedStringKey = "Not available"
    ) {
      self.title = title
      self.value = value
      self.placeholder = placeholder
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)

        if let displayValue {
          Text(displayValue)
            .font(.caption.monospaced())
            .foregroundStyle(.primary)
            .lineLimit(2)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
          Text(placeholder)
            .font(.caption.monospaced())
            .foregroundStyle(.tertiary)
            .lineLimit(2)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .accessibilityElement(children: .combine)
    }
  }
}

extension InspectorView {
  private struct WarningRow: View {
    let warning: SimulatorWarning

    var body: some View {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 6) {
          StatusBadge(
            title: LocalizedStringKey(warning.severity.displayTitle)
          )
          .tint(warning.severity.badgeTint)

          Text(warning.category.rawValue)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(warning.message)
          .font(.caption)
          .fixedSize(horizontal: false, vertical: true)

        if let relatedID = warning.relatedID {
          Text(relatedID)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
        }
      }
      .padding(10)
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .combine)
    }
  }
}

// MARK: - InspectorView Preview

#if DEBUG

#Preview {
  InspectorView(
    store: Store(initialState: MainWindowFeature.State.preview.workspace.inspector) {
      InspectorFeature()
    }
  )
  .frame(width: 320, height: 720)
}

#endif
