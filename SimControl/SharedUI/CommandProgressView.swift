import SwiftUI

struct CommandProgressView: View {
  let title: LocalizedStringKey
  let message: LocalizedStringKey

  var body: some View {
    HStack(spacing: 10) {
      ProgressView()
        .controlSize(.small)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.medium))

        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - CommandProgressView Preview

#Preview {
  CommandProgressView(title: "Title", message: "Message")
}
