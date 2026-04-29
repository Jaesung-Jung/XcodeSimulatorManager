import ComposableArchitecture
import SwiftUI

struct Sidebar: View {
  let store: StoreOf<SidebarFeature>

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

  var body: some View {
    List {
      Section("Inventory") {
        BarItem(
          title: "Devices",
          systemImage: "iphone",
          value: "\(store.snapshot?.devices.count ?? 0)"
        )
        BarItem(
          title: "Runtimes",
          systemImage: "shippingbox",
          value: "\(store.snapshot?.runtimes.count ?? 0)"
        )
        BarItem(
          title: "Warnings",
          systemImage: "exclamationmark.triangle",
          value: "\(store.snapshot?.warnings.count ?? 0)"
        )
      }

      Section("Platforms") {
        ForEach(platformCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: item.systemImage,
            value: "\(item.count)"
          )
        }
      }

      Section("Device State") {
        ForEach(stateCounts, id: \.title) { item in
          BarItem(
            title: LocalizedStringKey(item.title),
            systemImage: "circle.fill",
            value: "\(item.count)"
          )
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

// MARK: - SidebarView Preview

#if DEBUG

#Preview {
  Sidebar(
    store: Store(initialState: MainWindowFeature.State.preview.sidebar) {
      SidebarFeature()
    }
  )
  .frame(width: 240, height: 720)
}

#endif
