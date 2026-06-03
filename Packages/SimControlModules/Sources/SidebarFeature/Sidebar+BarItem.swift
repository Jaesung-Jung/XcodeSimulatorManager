import SwiftUI

// MARK: - Sidebar.BarItem

extension Sidebar {
  struct BarItem: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String

    var body: some View {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
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
