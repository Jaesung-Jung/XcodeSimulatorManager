import ComposableArchitecture
import SwiftUI

/// Renders the simulator device list column.
public struct DeviceListView: View {
  private let store: StoreOf<DeviceListFeature>

  /// Creates a device list view bound to a device list store.
  public init(store: StoreOf<DeviceListFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      Header(store: store)
      Divider()
      Content(store: store)
    }
  }
}

// MARK: - DeviceListView Preview

#if DEBUG

#Preview {
  DeviceListView(
    store: Store(initialState: DeviceListFeature.State()) {
      DeviceListFeature()
    }
  )
  .frame(width: 360, height: 720)
}

#endif
