import ComposableArchitecture
import SwiftUI

struct DeviceDetailView: View {
  let store: StoreOf<DeviceDetailFeature>

  private var appMetricValue: String {
    switch store.installedApps.availability {
    case .notLoaded:
      "Not loaded"
    case .loaded:
      "\(store.installedApps.apps.count)"
    }
  }

  var body: some View {
    if let device = store.device {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Header(
            device: device,
            runtime: store.runtime,
            deviceType: store.deviceType,
            deviceCommandState: store.deviceCommandState,
            isOpeningSimulatorApp: store.isOpeningSimulatorApp,
            onBoot: {
              store.send(.bootButtonTapped(device.id))
            },
            onShutdown: {
              store.send(.shutdownButtonTapped(device.id))
            },
            onOpenSimulatorApp: {
              store.send(.openSimulatorAppButtonTapped)
            },
            onRename: {
              store.send(.renameButtonTapped(device.id))
            }
          )

          MetricsGrid(
            device: device,
            runtimeName: store.runtime?.name ?? device.runtimeID,
            appMetricValue: appMetricValue
          )

          InstalledAppsView(
            store: store.scope(state: \.installedApps, action: \.installedApps)
          )

          DeveloperToolsSection()

          CommandResultsSection(results: store.commandResults)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
    }
  }
}

extension DeviceDetailView {
  private struct MetricsGrid: View {
    let device: SimulatorDevice
    let runtimeName: String
    let appMetricValue: String

    var body: some View {
      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 150), spacing: 10)
        ],
        alignment: .leading,
        spacing: 10
      ) {
        MetricTile(
          title: "Platform",
          value: device.platform.displayTitle,
          systemImage: device.platform.symbolName
        )
        MetricTile(
          title: "Runtime",
          value: runtimeName,
          systemImage: "shippingbox"
        )
        MetricTile(
          title: "Apps",
          value: appMetricValue,
          systemImage: "app"
        )
        MetricTile(
          title: "Data Size",
          value: device.dataPathSizeTitle,
          systemImage: "internaldrive"
        )
        MetricTile(
          title: "Availability",
          value: device.availabilityTitle,
          systemImage: device.isAvailable ? "checkmark.circle" : "exclamationmark.triangle"
        )
        MetricTile(
          title: "Last Booted",
          value: device.lastBootedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown",
          systemImage: "clock"
        )
      }
    }
  }
}

extension DeviceDetailView {
  private struct Header: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
    let deviceCommandState: DeviceCommandState?
    let isOpeningSimulatorApp: Bool
    let onBoot: () -> Void
    let onShutdown: () -> Void
    let onOpenSimulatorApp: () -> Void
    let onRename: () -> Void

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: device.platform.symbolName)
            .font(.system(size: 30, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(width: 36)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
              Text(device.name)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

              StatusBadge(
                title: LocalizedStringKey(device.state.displayTitle)
              )
              .tint(device.state.statusTint)
            }

            Text(subtitle)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            Text(device.udid)
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
              .lineLimit(1)
              .truncationMode(.middle)
          }

          Spacer()

          DeviceCommandControls(
            device: device,
            deviceCommandState: deviceCommandState,
            isOpeningSimulatorApp: isOpeningSimulatorApp,
            onBoot: onBoot,
            onShutdown: onShutdown,
            onOpenSimulatorApp: onOpenSimulatorApp,
            onRename: onRename
          )
        }
      }
      .padding(.bottom, 2)
    }
  }
}

extension DeviceDetailView {
  private struct DeviceCommandControls: View {
    let device: SimulatorDevice
    let deviceCommandState: DeviceCommandState?
    let isOpeningSimulatorApp: Bool
    let onBoot: () -> Void
    let onShutdown: () -> Void
    let onOpenSimulatorApp: () -> Void
    let onRename: () -> Void

    private var canBoot: Bool {
      device.isAvailable && device.state == .shutdown
    }

    private var canShutdown: Bool {
      device.isAvailable && device.state == .booted
    }

    private var isLifecycleActionRunning: Bool {
      deviceCommandState != nil
    }

    private var isBootRunning: Bool {
      deviceCommandState == DeviceCommandState(command: .boot, deviceID: device.id)
    }

    private var isShutdownRunning: Bool {
      deviceCommandState == DeviceCommandState(command: .shutdown, deviceID: device.id)
    }

    var body: some View {
      HStack(spacing: 8) {
        if canBoot {
          Button {
            onBoot()
          } label: {
            ActionButtonLabel(
              title: isBootRunning ? "Booting" : "Boot",
              systemImage: "power",
              isRunning: isBootRunning
            )
          }
          .disabled(isLifecycleActionRunning)
          .help("Boot selected simulator")
        }

        if canShutdown {
          Button {
            onShutdown()
          } label: {
            ActionButtonLabel(
              title: isShutdownRunning ? "Shutting Down" : "Shutdown",
              systemImage: "power",
              isRunning: isShutdownRunning
            )
          }
          .disabled(isLifecycleActionRunning)
          .help("Shut down selected simulator")
        }

        Button {
          onOpenSimulatorApp()
        } label: {
          ActionButtonLabel(
            title: isOpeningSimulatorApp ? "Opening" : "Open",
            systemImage: "play.rectangle",
            isRunning: isOpeningSimulatorApp
          )
        }
        .disabled(isOpeningSimulatorApp)
        .help("Open Simulator.app")

        Menu {
          Button {
            onRename()
          } label: {
            Label("Rename", systemImage: "pencil")
          }
          .disabled(isLifecycleActionRunning)
        } label: {
          Image(systemName: "ellipsis.circle")
            .accessibilityLabel("More device actions")
        }
        .disabled(isLifecycleActionRunning)
        .help("More device actions")
      }
      .buttonStyle(.bordered)
    }
  }
}

extension DeviceDetailView {
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
      .frame(minWidth: 78)
    }
  }
}

extension DeviceDetailView {
  private struct MetricTile: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: systemImage)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Text(value)
          .font(.subheadline.weight(.medium))
          .lineLimit(2)
          .truncationMode(.middle)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(10)
      .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .combine)
    }
  }
}

extension DeviceDetailView {
  private struct DeveloperToolsSection: View {
    private let tools: [(id: String, title: LocalizedStringKey, systemImage: String)] = [
      ("deep-link", "Deep Link", "link"),
      ("notification", "Notification", "bell.badge"),
      ("logs", "Logs", "doc.text.magnifyingglass"),
      ("diagnostics", "Diagnostics", "stethoscope")
    ]

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        SectionHeader(title: "Developer Tools", systemImage: "wrench.and.screwdriver")

        HStack(spacing: 8) {
          ForEach(tools, id: \.id) { tool in
            Button {
            } label: {
              Label(tool.title, systemImage: tool.systemImage)
                .frame(maxWidth: .infinity)
            }
            .disabled(true)
          }
        }
      }
    }
  }
}

extension DeviceDetailView {
  private struct CommandResultsSection: View {
    let results: [CommandResult]

    private var recentResults: [CommandResult] {
      Array(results.suffix(5).reversed())
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        SectionHeader(title: "Recent Command Results", systemImage: "terminal")

        if recentResults.isEmpty {
          EmptyStateView(
            title: "No Command Results",
            message: "Recent simulator commands will appear here after refresh or actions run.",
            systemImage: "terminal"
          )
          .frame(maxWidth: .infinity)
        } else {
          VStack(spacing: 0) {
            ForEach(recentResults) { result in
              CommandResultRow(result: result)

              if result.id != recentResults.last?.id {
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

extension DeviceDetailView {
  private struct CommandResultRow: View {
    let result: CommandResult

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
            .foregroundStyle(result.succeeded ? .green : .red)
            .accessibilityHidden(true)

          Text(result.commandLineSummary)
            .font(.caption.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)

          Spacer()

          Text(result.durationTitle)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 8) {
          StatusBadge(
            title: result.succeeded ? LocalizedStringKey("Succeeded") : LocalizedStringKey("Failed")
          )
          .tint(result.succeeded ? .green : .red)

          Text(result.startedAt.formatted(date: .omitted, time: .shortened))
            .font(.caption)
            .foregroundStyle(.secondary)

          if !result.succeeded {
            Text("Exit \(result.exitCode)")
              .font(.caption.monospacedDigit())
              .foregroundStyle(.secondary)
          }
        }

        if !result.succeeded, !result.stderr.isEmpty {
          Text(result.stderr)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .textSelection(.enabled)
        }
      }
      .padding(10)
      .accessibilityElement(children: .combine)
    }
  }
}

// MARK: - DeviceDetailView Preview

#if DEBUG

#Preview {
  DeviceDetailView(
    store: Store(
      initialState: MainWindowFeature.State.preview.workspace.deviceDetail
    ) {
      DeviceDetailFeature()
    }
  )
  .frame(width: 640, height: 720)
}

#endif
