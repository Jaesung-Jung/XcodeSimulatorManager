import SwiftUI

/// A compact status label with an optional SF Symbol.
public struct StatusBadge: View {
  let title: LocalizedStringKey
  let systemImage: String?

  public init(title: LocalizedStringKey, systemImage: String? = nil) {
    self.title = title
    self.systemImage = systemImage
  }

  public var body: some View {
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
    .background(.quaternary, in: Capsule())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
  }
}

// MARK: - StatusBadge Preview

#Preview {
  StatusBadge(title: "Title", systemImage: "apple.logo")
    .tint(.green)
    .padding(20)
}
