import SwiftUI

struct StatusBadgeView: View {
  let title: LocalizedStringKey
  let systemImage: String?

  init(title: LocalizedStringKey, systemImage: String? = nil) {
    self.title = title
    self.systemImage = systemImage
  }

  var body: some View {
    HStack(spacing: 4) {
      if let systemImage {
        Image(systemName: systemImage)
          .imageScale(.small)
          .accessibilityHidden(true)
      }

      Text(title)
        .lineLimit(1)
    }
    .font(.caption2.weight(.semibold))
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .foregroundStyle(.tint)
    .background(.quaternary.opacity(0.55), in: Capsule())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
  }
}

// MARK: - StatusBadgeView Preview

#Preview {
  StatusBadgeView(title: "Title", systemImage: "apple.logo")
    .tint(.green)
    .padding(20)
}
