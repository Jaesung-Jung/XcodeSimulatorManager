import SwiftUI

struct PathRowView: View {
  let title: LocalizedStringKey
  let value: String?
  let placeholder: LocalizedStringKey

  init(
    title: LocalizedStringKey,
    value: String?,
    placeholder: LocalizedStringKey = "Not available"
  ) {
    self.title = title
    self.value = value
    self.placeholder = placeholder
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)

      if let displayValue {
        Text(displayValue)
          .font(.caption.monospaced())
          .foregroundStyle(.primary)
          .lineLimit(2)
          .truncationMode(.middle)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text(placeholder)
          .font(.caption.monospaced())
          .foregroundStyle(.tertiary)
          .lineLimit(2)
          .truncationMode(.middle)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var displayValue: String? {
    guard let value, !value.isEmpty else {
      return nil
    }
    return value
  }
}

// MARK: - PathRowView Preview

#Preview {
  PathRowView(
    title: "Title",
    value: "Value",
    placeholder: "Placeholder"
  )
  .padding(20)
}
