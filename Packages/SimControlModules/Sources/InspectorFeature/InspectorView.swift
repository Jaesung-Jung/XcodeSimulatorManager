import ComposableArchitecture
import SwiftUI

/// Renders the inspector pane for the selected simulator context.
public struct InspectorView: View {
  private let store: StoreOf<InspectorFeature>

  /// Creates an inspector view bound to an inspector store.
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
