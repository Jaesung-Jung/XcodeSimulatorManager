import MainWindowDisplaySupport
import SimControlDomain
import SwiftUI

// MARK: - Sidebar Projection Values

extension Sidebar {
  struct PlatformCount {
    let platform: SimulatorPlatform
    let title: String
    let systemImage: String
    let count: Int
  }

  struct RuntimeCount {
    let runtime: SimulatorRuntime
    let count: Int
  }

  struct StateCount {
    let state: SimulatorDevice.State
    let title: String
    let tint: Color
    let count: Int
  }
}

extension SimulatorSnapshot {
  var platformCounts: [Sidebar.PlatformCount] {
    let grouped = Dictionary(grouping: devices, by: \.platform)
    return grouped
      .map { platform, devices in
        Sidebar.PlatformCount(
          platform: platform,
          title: platform.displayTitle,
          systemImage: platform.symbolName,
          count: devices.count
        )
      }
      .sorted { $0.title < $1.title }
  }

  var runtimeCounts: [Sidebar.RuntimeCount] {
    let grouped = Dictionary(grouping: devices, by: \.runtimeID)
    return runtimes
      .compactMap { runtime in
        guard let devices = grouped[runtime.id] else {
          return nil
        }

        return Sidebar.RuntimeCount(
          runtime: runtime,
          count: devices.count
        )
      }
      .sorted { $0.runtime.name < $1.runtime.name }
  }

  var stateCounts: [Sidebar.StateCount] {
    let grouped = Dictionary(grouping: devices, by: \.state)
    return grouped
      .map { state, devices in
        Sidebar.StateCount(
          state: state,
          title: state.displayTitle,
          tint: state.statusTint,
          count: devices.count
        )
      }
      .sorted { $0.title < $1.title }
  }

  var warnedDeviceCount: Int {
    let warningRelatedIDs = Set(warnings.compactMap(\.relatedID))
    return devices.filter { warningRelatedIDs.contains($0.id) }.count
  }
}
