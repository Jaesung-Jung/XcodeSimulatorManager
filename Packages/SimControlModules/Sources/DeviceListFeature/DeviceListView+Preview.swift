#if DEBUG

import ComposableArchitecture
import SwiftUI

#Preview {
  DeviceListView(
    store: Store(
      initialState: DeviceListFeature.State()
    ) {
      DeviceListFeature()
    }
  )
  .frame(width: 360, height: 720)
}

#endif
