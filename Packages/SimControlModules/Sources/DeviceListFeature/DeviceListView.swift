import ComposableArchitecture
import SwiftUI

public struct DeviceListView: View {
  private let store: StoreOf<DeviceListFeature>

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
