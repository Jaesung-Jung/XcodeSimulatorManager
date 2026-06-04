import MainWindowDisplaySupport
import SimControlDomain
import SimControlSharedUI
import SwiftUI

// MARK: - InspectorView.WarningRow

extension InspectorView {
  struct WarningRow: View {
    let warning: SimulatorWarning

    var body: some View {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 6) {
          StatusBadge(
            title: LocalizedStringKey(warning.severity.displayTitle)
          )
          .tint(warning.severity.badgeTint)

          Text(warning.category.rawValue)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(warning.message)
          .font(.caption)

        if let relatedID = warning.relatedID {
          Text(relatedID)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
        }
      }
      .padding(10)
      .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
      .accessibilityElement(children: .combine)
    }
  }
}

// MARK: - InspectorView.WarningRow Preview

#if DEBUG

#Preview {
  InspectorView.WarningRow(
    warning: SimulatorWarning(
      id: "preview-warning",
      severity: .warning,
      category: .device,
      message: "Preview warning for simulator inventory.",
      relatedID: "PREVIEW-DEVICE-1"
    )
  )
  .padding(20)
  .frame(width: 320)
}

#endif
