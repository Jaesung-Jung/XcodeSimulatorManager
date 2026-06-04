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

// MARK: - InspectorView.InspectorSection Preview

#if DEBUG

#Preview {
  InspectorView.InspectorSection("Preview Section") {
    InspectorView.FieldRow(title: "Name", value: "iPhone 17 Pro")
    InspectorView.FieldRow(title: "State", value: "Booted")
  }
  .padding(20)
  .frame(width: 320)
}

#endif
