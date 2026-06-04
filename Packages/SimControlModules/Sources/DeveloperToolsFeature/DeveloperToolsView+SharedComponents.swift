import SimControlSharedUI
import SwiftUI

extension DeveloperToolsView {
  struct ToolSection<Content: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let content: () -> Content

    init(
      title: LocalizedStringKey,
      systemImage: String,
      @ViewBuilder content: @escaping () -> Content
    ) {
      self.title = title
      self.systemImage = systemImage
      self.content = content
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        SectionHeader(title: title, systemImage: systemImage)

        content()
      }
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
  }
}

extension DeveloperToolsView {
  struct ToolPanel<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
      self.content = content
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        content()
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

extension DeveloperToolsView {
  struct BundleIDRow: View {
    @Binding var bundleID: String

    let bundleIDOptions: [String]
    let selectedAppBundleID: String?
    let onUseSelectedApp: () -> Void

    var body: some View {
      HStack(spacing: 8) {
        TextField("Bundle Identifier", text: $bundleID)
          .textFieldStyle(.roundedBorder)
          .font(.system(.body, design: .monospaced))

        if !bundleIDOptions.isEmpty {
          Menu {
            ForEach(bundleIDOptions, id: \.self) { bundleID in
              Button(bundleID) {
                self.bundleID = bundleID
              }
            }
          } label: {
            Image(systemName: "list.bullet")
              .accessibilityLabel("Known bundle identifiers")
          }
          .help("Known bundle identifiers")
        }

        if selectedAppBundleID != nil {
          Button {
            onUseSelectedApp()
          } label: {
            Image(systemName: "scope")
              .accessibilityLabel("Use selected app bundle identifier")
          }
          .help("Use selected app bundle identifier")
        }
      }
    }
  }
}

extension DeveloperToolsView {
  struct ServiceMenu: View {
    let selectedService: DeveloperToolsFeature.PrivacyService
    let onServiceSelected: (DeveloperToolsFeature.PrivacyService) -> Void

    var body: some View {
      Menu {
        ForEach(DeveloperToolsFeature.PrivacyService.allCases) { service in
          Button {
            onServiceSelected(service)
          } label: {
            if service == selectedService {
              Label {
                Text(service.displayTitle)
              } icon: {
                Image(systemName: "checkmark")
              }
            } else {
              Text(service.displayTitle)
            }
          }
          .disabled(service.unsupportedReason != nil)
          .help(service.unsupportedReason ?? service.simctlArgument)
        }
      } label: {
        Label {
          Text(selectedService.displayTitle)
        } icon: {
          Image(systemName: "hand.raised")
        }
      }
      .help(selectedService.unsupportedReason ?? selectedService.simctlArgument)
    }
  }
}

extension DeveloperToolsView {
  struct ToolButtonLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    let isRunning: Bool

    var body: some View {
      HStack(spacing: 6) {
        if isRunning {
          ProgressView()
            .controlSize(.small)
            .frame(width: 14, height: 14)
        } else {
          Image(systemName: systemImage)
            .accessibilityHidden(true)
        }

        Text(title)
          .lineLimit(1)
      }
      .frame(minWidth: 82)
    }
  }
}

extension DeveloperToolsView {
  struct ToolStatusText: View {
    let value: String?

    init(_ value: String?) {
      self.value = value
    }

    var body: some View {
      if let value {
        Text(value)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
  }
}

// MARK: - ToolPanel Preview

#if DEBUG

#Preview {
  VStack(alignment: .leading, spacing: 12) {
    DeveloperToolsView.ToolSection(title: "Preview Tool", systemImage: "wrench") {
      DeveloperToolsView.ToolPanel {
        DeveloperToolsView.BundleIDRow(
          bundleID: .constant("com.example.preview"),
          bundleIDOptions: ["com.example.preview"],
          selectedAppBundleID: "com.example.preview",
          onUseSelectedApp: {}
        )

        DeveloperToolsView.ServiceMenu(
          selectedService: .location,
          onServiceSelected: { _ in }
        )

        DeveloperToolsView.ToolButtonLabel(
          title: "Run",
          systemImage: "play.fill",
          isRunning: false
        )

        DeveloperToolsView.ToolStatusText("Ready")
      }
    }
  }
  .padding(20)
  .frame(width: 420)
}

#endif
