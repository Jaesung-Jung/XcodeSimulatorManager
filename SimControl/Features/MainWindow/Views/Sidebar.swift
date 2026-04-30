import ComposableArchitecture
import SwiftUI

struct Sidebar: View {
  let store: StoreOf<SidebarFeature>
  let filters: SimulatorFilters
  let onScopeSelected: (SimulatorFilters.SidebarScope) -> Void

  private var platformCounts: [(title: String, systemImage: String, count: Int)] {
    guard let devices = store.snapshot?.devices else {
      return []
    }

    let grouped = Dictionary(grouping: devices, by: \.platform)
    return grouped
      .map { platform, devices in
        (
          title: platform.displayTitle,
          systemImage: platform.symbolName,
          count: devices.count
        )
      }
      .sorted { $0.title < $1.title }
  }

  private var runtimeCounts: [(runtime: SimulatorRuntime, count: Int)] {
    guard let snapshot = store.snapshot else {
      return []
    }

    let grouped = Dictionary(grouping: snapshot.devices, by: \.runtimeID)
    return snapshot.runtimes
      .compactMap { runtime in
        guard let devices = grouped[runtime.id] else {
          return nil
        }

        return (runtime: runtime, count: devices.count)
      }
      .sorted { $0.runtime.name < $1.runtime.name }
  }

  private var stateCounts: [(title: String, tint: Color, count: Int)] {
    guard let devices = store.snapshot?.devices else {
      return []
    }

    let grouped = Dictionary(grouping: devices, by: \.state)
    return grouped
      .map { state, devices in
        (
          title: state.displayTitle,
          tint: state.statusTint,
          count: devices.count
        )
      }
      .sorted { $0.title < $1.title }
  }

  private var xcodeTitle: String {
    guard let snapshot = store.snapshot else {
      return "Xcode"
    }

    return snapshot.xcode.isValid ? "Xcode Ready" : "Xcode Issue"
  }

  private var xcodeValue: String {
    if store.refreshState == .refreshing {
      return "Loading"
    }

    guard let snapshot = store.snapshot else {
      return "Not loaded"
    }

    return snapshot.xcode.developerPath?.lastPathComponent ?? "Unknown"
  }

  private var warnedDeviceCount: Int {
    guard let snapshot = store.snapshot else {
      return 0
    }

    let warningRelatedIDs = Set(snapshot.warnings.compactMap(\.relatedID))
    return snapshot.devices.filter { warningRelatedIDs.contains($0.id) }.count
  }

  private var sidebarScopeSelection: Binding<SimulatorFilters.SidebarScope?> {
    Binding(
      get: { filters.sidebarScope },
      set: { scope in
        guard let scope else {
          return
        }

        onScopeSelected(scope)
      }
    )
  }

  var body: some View {
    List(selection: sidebarScopeSelection) {
      Section("Inventory") {
        BarItem(
          title: "All Devices",
          systemImage: "iphone",
          value: "\(store.snapshot?.devices.count ?? 0)"
        )
        .tag(SimulatorFilters.SidebarScope.all)

        BarItem(
          title: "Pinned",
          systemImage: "pin",
          value: "\(visiblePinnedDeviceCount)"
        )
        .tag(SimulatorFilters.SidebarScope.pinned)

        BarItem(
          title: "Recent",
          systemImage: "clock",
          value: "\(visibleRecentDeviceCount)"
        )
        .tag(SimulatorFilters.SidebarScope.recent)

        BarItem(
          title: "Warnings",
          systemImage: "exclamationmark.triangle",
          value: "\(warnedDeviceCount)"
        )
        .tag(SimulatorFilters.SidebarScope.warnings)
      }

      Section("Platforms") {
        ForEach(platformCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: item.systemImage,
            value: "\(item.count)"
          )
          .tag(SimulatorFilters.SidebarScope.platform(platform(for: item.title)))
        }
      }

      Section("Runtimes") {
        ForEach(runtimeCounts, id: \.runtime.id) { item in
          BarItem(
            title: LocalizedStringKey(item.runtime.name),
            systemImage: item.runtime.platform.symbolName,
            value: "\(item.count)"
          )
          .tag(SimulatorFilters.SidebarScope.runtime(item.runtime.id))
        }
      }

      Section("Device State") {
        ForEach(stateCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: "circle.fill",
            value: "\(item.count)"
          )
          .tag(SimulatorFilters.SidebarScope.state(state(for: item.title)))
          .tint(item.tint)
        }
      }

      Section("Environment") {
        BarItem(
          title: LocalizedStringKey(xcodeTitle),
          systemImage: "hammer",
          value: xcodeValue
        )

        if case .failed(let diagnostic) = store.refreshState {
          Text(diagnostic)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("SimControl")
  }

  private var visiblePinnedDeviceCount: Int {
    store.snapshot?.devices.filter { filters.pinnedDeviceIDs.contains($0.id) }.count ?? 0
  }

  private var visibleRecentDeviceCount: Int {
    store.snapshot?.devices.filter { filters.recentDeviceIDs.contains($0.id) }.count ?? 0
  }

  private func platform(for title: String) -> SimulatorPlatform {
    SimulatorPlatform.allDisplayableCases.first { $0.displayTitle == title } ?? .unknown
  }

  private func state(for title: String) -> SimulatorDevice.State {
    SimulatorDevice.State.allDisplayableCases.first { $0.displayTitle == title } ?? .unknown
  }
}

extension Sidebar {
  private struct BarItem: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String

    var body: some View {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .foregroundStyle(.tint)
          .frame(width: 18)
          .accessibilityHidden(true)

        Text(title)
          .lineLimit(1)

        Spacer()

        Text(value)
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)
    }
  }
}

private extension SimulatorPlatform {
  static var allDisplayableCases: [SimulatorPlatform] {
    [.iOS, .watchOS, .tvOS, .visionOS, .unknown]
  }
}

private extension SimulatorDevice.State {
  static var allDisplayableCases: [SimulatorDevice.State] {
    [.booted, .booting, .shutdown, .shuttingDown, .creating, .unknown]
  }
}

// MARK: - SidebarView Preview

#if DEBUG

#Preview {
  Sidebar(
    store: Store(initialState: MainWindowFeature.State.preview.sidebar) {
      SidebarFeature()
    },
    filters: MainWindowFeature.State.preview.workspace.filters,
    onScopeSelected: { _ in }
  )
  .frame(width: 240, height: 720)
}

#endif
