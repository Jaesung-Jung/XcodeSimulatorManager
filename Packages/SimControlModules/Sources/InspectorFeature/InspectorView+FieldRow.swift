import SwiftUI

// MARK: - InspectorView.FieldRow

extension InspectorView {
  struct FieldRow: View {
    let title: LocalizedStringKey
    let value: String?
    let placeholder: LocalizedStringKey
    let onOpen: (() -> Void)?
    let onCopy: (() -> Void)?

    private var displayValue: String? {
      guard let value, !value.isEmpty else {
        return nil
      }
      return value
    }

    private var canActOnValue: Bool { displayValue != nil }

    init(
      title: LocalizedStringKey,
      value: String?,
      placeholder: LocalizedStringKey = "Not available",
      onOpen: (() -> Void)? = nil,
      onCopy: (() -> Void)? = nil
    ) {
      self.title = title
      self.value = value
      self.placeholder = placeholder
      self.onOpen = onOpen
      self.onCopy = onCopy
    }

    var body: some View {
      HStack(alignment: .top, spacing: 8) {
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

        Spacer(minLength: 4)

        HStack(spacing: 4) {
          if let onOpen {
            Button {
              onOpen()
            } label: {
              Image(systemName: "arrow.up.forward.square")
                .accessibilityLabel("Open")
            }
            .disabled(!canActOnValue)
            .help("Open")
          }

          if let onCopy {
            Button {
              onCopy()
            } label: {
              Image(systemName: "doc.on.doc")
                .accessibilityLabel("Copy")
            }
            .disabled(!canActOnValue)
            .help("Copy")
          }
        }
        .buttonStyle(.borderless)
      }
      .accessibilityElement(children: .combine)
    }
  }
}

// MARK: - InspectorView.FieldRow Preview

#if DEBUG

#Preview {
  VStack(alignment: .leading, spacing: 12) {
    InspectorView.FieldRow(
      title: "Bundle ID",
      value: "com.example.preview",
      onOpen: {},
      onCopy: {}
    )

    InspectorView.FieldRow(
      title: "Data",
      value: nil
    )
  }
  .padding(20)
  .frame(width: 320)
}

#endif
