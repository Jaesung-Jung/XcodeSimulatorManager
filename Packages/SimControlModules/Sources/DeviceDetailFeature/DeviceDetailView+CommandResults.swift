import SimControlDomain
import SimControlSharedUI
import SwiftUI

// MARK: - DeviceDetailView.CommandResultsSection

extension DeviceDetailView {
  struct CommandResultsSection: View {
    let results: [CommandResult]

    private var recentResults: [CommandResult] { Array(results.suffix(5).reversed()) }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        SectionHeader(title: "Recent Command Results", systemImage: "terminal")

        if recentResults.isEmpty {
          EmptyStateView(
            title: "No Command Results",
            message: "Recent simulator commands will appear here after refresh or actions run.",
            systemImage: "terminal"
          )
          .frame(maxWidth: .infinity)
        } else {
          VStack(spacing: 0) {
            ForEach(recentResults) { result in
              CommandResultRow(result: result)

              if result.id != recentResults.last?.id {
                Divider()
              }
            }
          }
          .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        }
      }
    }
  }
}

// MARK: - DeviceDetailView.CommandResultsSection Preview

#if DEBUG

#Preview {
  let result = CommandResult(
    id: "preview-command",
    executable: "xcrun",
    arguments: ["simctl", "boot", "PREVIEW-DEVICE-1"],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.24,
    startedAt: Date(timeIntervalSince1970: 1_000)
  )

  DeviceDetailView.CommandResultsSection(results: [result])
    .padding(20)
    .frame(width: 520)
}

#endif

// MARK: - DeviceDetailView.CommandResultRow

extension DeviceDetailView {
  struct CommandResultRow: View {
    let result: CommandResult

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
            .foregroundStyle(result.succeeded ? .green : .red)
            .accessibilityHidden(true)

          Text(result.commandLineSummary)
            .font(.caption.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)

          Spacer()

          Text(result.durationTitle)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 8) {
          StatusBadge(
            title: result.succeeded ? LocalizedStringKey("Succeeded") : LocalizedStringKey("Failed")
          )
          .tint(result.succeeded ? .green : .red)

          Text(result.startedAt.formatted(date: .omitted, time: .shortened))
            .font(.caption)
            .foregroundStyle(.secondary)

          if !result.succeeded {
            Text("Exit \(result.exitCode)")
              .font(.caption.monospacedDigit())
              .foregroundStyle(.secondary)
          }
        }

        if !result.succeeded, !result.stderr.isEmpty {
          Text(result.stderr)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .textSelection(.enabled)
        }
      }
      .padding(10)
      .accessibilityElement(children: .combine)
    }
  }
}
