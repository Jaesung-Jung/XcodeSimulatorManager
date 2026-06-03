import SwiftUI

struct SectionHeader: View {
  let title: LocalizedStringKey
  let systemImage: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: systemImage)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Text(title)
        .font(.headline)
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - SectionHeader Preview

#if DEBUG

#Preview {
  SectionHeader(
    title: "Section",
    systemImage: "rectangle.grid.1x2"
  )
  .padding(20)
}

#endif
