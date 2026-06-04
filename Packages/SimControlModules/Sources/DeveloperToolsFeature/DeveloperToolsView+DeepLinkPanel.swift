import SwiftUI

extension DeveloperToolsView {
  struct DeepLinkPanel: View {
    @Binding var urlString: String

    let recentURLs: [String]
    let disabledReason: String?
    let isRunning: Bool
    let onRecentSelected: (String) -> Void
    let onOpen: () -> Void

    var body: some View {
      ToolPanel {
        TextField("myapp://path", text: $urlString)
          .textFieldStyle(.roundedBorder)

        HStack(spacing: 8) {
          if !recentURLs.isEmpty {
            Menu {
              ForEach(recentURLs, id: \.self) { urlString in
                Button(urlString) {
                  onRecentSelected(urlString)
                }
              }
            } label: {
              Label("Recent", systemImage: "clock.arrow.circlepath")
            }
          }

          Spacer()

          Button {
            onOpen()
          } label: {
            ToolButtonLabel(
              title: isRunning ? "Opening" : "Open URL",
              systemImage: "arrow.up.forward.app",
              isRunning: isRunning
            )
          }
          .disabled(disabledReason != nil)
          .help(disabledReason ?? "Open URL on selected simulator")
        }

        ToolStatusText(disabledReason)
      }
    }
  }
}

// MARK: - DeepLinkPanel Preview

#if DEBUG

#Preview {
  DeveloperToolsView.DeepLinkPanel(
    urlString: .constant("simcontrol://open/device"),
    recentURLs: [
      "simcontrol://open/device",
      "myapp://preview"
    ],
    disabledReason: nil,
    isRunning: false,
    onRecentSelected: { _ in },
    onOpen: {}
  )
  .padding(20)
  .frame(width: 360)
}

#endif
