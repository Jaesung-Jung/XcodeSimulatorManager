import SimControlSharedUI
import SwiftUI
import Testing

@Suite("SharedUISmokeTests")
struct SharedUISmokeTests {
  @Test func sharedViewsCanBeConstructedFromOutsideTheModule() {
    _ = EmptyStateView(
      title: "Title",
      message: "Message",
      systemImage: "apple.logo"
    )
    _ = SectionHeader(title: "Section", systemImage: "rectangle.grid.1x2")
    _ = StatusBadge(title: "Ready", systemImage: "checkmark.circle")
  }
}
