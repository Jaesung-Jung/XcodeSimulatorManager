import SwiftUI

// MARK: - InspectorView.InspectorSection

extension InspectorView {
  struct InspectorSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
      self.title = title
      self.content = content()
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        Text(title)
          .font(.headline)

        VStack(alignment: .leading, spacing: 10) {
          content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
