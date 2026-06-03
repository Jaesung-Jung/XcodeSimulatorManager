import ComposableArchitecture
import SwiftUI

// MARK: - DeviceDetailView Preview

#if DEBUG

#Preview {
  DeviceDetailView(
    store: Store(
      initialState: DeviceDetailFeature.State()
    ) {
      DeviceDetailFeature()
    }
  )
  .frame(width: 640, height: 720)
}

#endif
