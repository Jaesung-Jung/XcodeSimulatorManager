import SwiftUI

extension DeveloperToolsView {
  struct PushPanel: View {
    @Binding var bundleID: String
    @Binding var payloadJSON: String

    let bundleIDOptions: [String]
    let selectedAppBundleID: String?
    let disabledReason: String?
    let isRunning: Bool
    let onUseSelectedApp: () -> Void
    let onSend: () -> Void

    var body: some View {
      ToolPanel(title: "Push Notification", systemImage: "bell.badge") {
        BundleIDRow(
          bundleID: $bundleID,
          bundleIDOptions: bundleIDOptions,
          selectedAppBundleID: selectedAppBundleID,
          onUseSelectedApp: onUseSelectedApp
        )

        TextEditor(text: $payloadJSON)
          .font(.system(.caption, design: .monospaced))
          .frame(minHeight: 94)
          .scrollContentBackground(.hidden)
          .background(.background, in: RoundedRectangle(cornerRadius: 6))
          .overlay {
            RoundedRectangle(cornerRadius: 6)
              .stroke(.quaternary)
          }

        HStack {
          Spacer()

          Button {
            onSend()
          } label: {
            ToolButtonLabel(
              title: isRunning ? "Sending" : "Send Push",
              systemImage: "paperplane",
              isRunning: isRunning
            )
          }
          .disabled(disabledReason != nil)
          .help(disabledReason ?? "Send simulated push notification")
        }

        ToolStatusText(disabledReason)
      }
    }
  }
}

// MARK: - PushPanel Preview

#if DEBUG

#Preview {
  DeveloperToolsView.PushPanel(
    bundleID: .constant("com.example.preview"),
    payloadJSON: .constant("{\n  \"aps\": {\n    \"alert\": \"Preview\"\n  }\n}"),
    bundleIDOptions: ["com.example.preview"],
    selectedAppBundleID: "com.example.preview",
    disabledReason: nil,
    isRunning: false,
    onUseSelectedApp: {},
    onSend: {}
  )
  .padding(20)
  .frame(width: 420)
}

#endif
