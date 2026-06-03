import SwiftUI

struct EmptyStateView: View {
  let title: LocalizedStringKey
  let message: LocalizedStringKey
  let systemImage: String
  let action: Action?

  init(
    title: LocalizedStringKey,
    message: LocalizedStringKey,
    systemImage: String,
    action: EmptyStateView.Action? = nil,
  ) {
    self.title = title
    self.message = message
    self.systemImage = systemImage
    self.action = action
  }

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 32, weight: .regular))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      VStack(spacing: 4) {
        Text(title)
          .font(.headline)

        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      if let action {
        Button(action.title, action: action.handler)
      }
    }
    .frame(maxWidth: 360)
    .padding(24)
  }
}

extension EmptyStateView {
  struct Action {
    let title: LocalizedStringKey
    let handler: @MainActor () -> Void

    static func action(_ title: LocalizedStringKey, handler: @MainActor @escaping () -> Void) -> Action {
      Action(title: title, handler: handler)
    }
  }
}

// MARK: - EmptyStateView Preview

#Preview {
  EmptyStateView(
    title: "Title",
    message: "Message",
    systemImage: "apple.logo",
    action: .action("Action") {})
}
