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

// MARK: - Sidebar.BarItem Preview

#if DEBUG

#Preview {
  List {
    Sidebar.BarItem(
      title: "Booted",
      systemImage: "circle.fill",
      value: "3"
    )
  }
  .listStyle(.sidebar)
  .frame(width: 240)
}

#endif
