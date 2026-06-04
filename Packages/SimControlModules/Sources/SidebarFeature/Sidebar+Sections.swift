import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

// MARK: - Sidebar.InventorySection

extension Sidebar {
  struct InventorySection: View {
    let snapshot: SimulatorSnapshot?
    let filters: SimulatorFilters

    private var visiblePinnedDeviceCount: Int {
      snapshot?.devices.filter { filters.pinnedDeviceIDs.contains($0.id) }.count ?? 0
    }

    var body: some View {
      Section("Inventory") {
        BarItem(
          title: "All Devices",
          systemImage: "iphone",
          value: "\(snapshot?.devices.count ?? 0)"
        )
        .tag(SimulatorFilters.SidebarScope.all)

        BarItem(
          title: "Pinned",
          systemImage: "pin",
          value: "\(visiblePinnedDeviceCount)"
        )
        .tag(SimulatorFilters.SidebarScope.pinned)

        BarItem(
          title: "Warnings",
          systemImage: "exclamationmark.triangle",
          value: "\(snapshot?.warnedDeviceCount ?? 0)"
        )
        .tag(SimulatorFilters.SidebarScope.warnings)
      }
    }
  }
}

// MARK: - Sidebar.InventorySection Preview

#if DEBUG

#Preview {
  List {
    Sidebar.InventorySection(
      snapshot: nil,
      filters: SimulatorFilters()
    )

    Sidebar.PlatformsSection(
      platformCounts: [
        Sidebar.PlatformCount(
          platform: .iOS,
          title: "iOS",
          systemImage: "iphone",
          count: 3
        )
      ]
    )

    Sidebar.RuntimesSection(runtimeCounts: [])
    Sidebar.DeviceStateSection(stateCounts: [])
    Sidebar.EnvironmentSection(snapshot: nil, refreshState: .idle)
  }
  .listStyle(.sidebar)
  .frame(width: 240, height: 520)
}

#endif

// MARK: - Sidebar.PlatformsSection

extension Sidebar {
  struct PlatformsSection: View {
    let platformCounts: [PlatformCount]

    var body: some View {
      Section("Platforms") {
        ForEach(platformCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: item.systemImage,
            value: "\(item.count)"
          )
          .tag(SimulatorFilters.SidebarScope.platform(item.platform))
        }
      }
    }
  }
}

// MARK: - Sidebar.RuntimesSection

extension Sidebar {
  struct RuntimesSection: View {
    let runtimeCounts: [RuntimeCount]

    var body: some View {
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
    }
  }
}

// MARK: - Sidebar.DeviceStateSection

extension Sidebar {
  struct DeviceStateSection: View {
    let stateCounts: [StateCount]

    var body: some View {
      Section("Device State") {
        ForEach(stateCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: "circle.fill",
            value: "\(item.count)"
          )
          .tag(SimulatorFilters.SidebarScope.state(item.state))
          .tint(item.tint)
        }
      }
    }
  }
}

// MARK: - Sidebar.EnvironmentSection

extension Sidebar {
  struct EnvironmentSection: View {
    let snapshot: SimulatorSnapshot?
    let refreshState: InventoryRefreshState

    private var xcodeValue: String {
      if refreshState == .refreshing {
        return "Loading"
      }

      guard let snapshot else {
        return "Not loaded"
      }

      return snapshot.xcode.developerPath?.lastPathComponent ?? "Unknown"
    }

    var body: some View {
      Section("Environment") {
        BarItem(
          title: "Xcode",
          systemImage: "hammer",
          value: xcodeValue
        )

        if case .failed(let diagnostic) = refreshState {
          Text(diagnostic)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
      }
    }
  }
}
