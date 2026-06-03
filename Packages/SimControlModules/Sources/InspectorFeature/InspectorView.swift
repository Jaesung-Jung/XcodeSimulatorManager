import ComposableArchitecture
import SwiftUI

public struct InspectorView: View {
  private let store: StoreOf<InspectorFeature>

  public init(store: StoreOf<InspectorFeature>) {
    self.store = store
  }

  public var body: some View {
    Content(store: store)
  }
}

// MARK: - InspectorView Preview

#if DEBUG

#Preview {
  InspectorView(
    store: Store(initialState: InspectorFeature.State()) {
      InspectorFeature()
    }
  )
  .frame(width: 320, height: 720)
}

#endif
