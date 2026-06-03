import SwiftUI

extension DeveloperToolsView {
  struct PrivacyPanel: View {
    @Binding var action: DeveloperToolsFeature.PrivacyAction
    @Binding var bundleID: String

    let service: DeveloperToolsFeature.PrivacyService
    let bundleIDOptions: [String]
    let selectedAppBundleID: String?
    let disabledReason: String?
    let isRunning: Bool
    let onServiceSelected: (DeveloperToolsFeature.PrivacyService) -> Void
    let onUseSelectedApp: () -> Void
    let onApply: () -> Void

    var body: some View {
      ToolPanel(title: "Privacy Permission", systemImage: "hand.raised") {
        Picker("Action", selection: $action) {
          ForEach(DeveloperToolsFeature.PrivacyAction.allCases) { action in
            Text(action.displayTitle)
              .tag(action)
          }
        }
        .pickerStyle(.segmented)

        HStack(spacing: 8) {
          ServiceMenu(
            selectedService: service,
            onServiceSelected: onServiceSelected
          )

          Spacer()
        }

        BundleIDRow(
          bundleID: $bundleID,
          bundleIDOptions: bundleIDOptions,
          selectedAppBundleID: selectedAppBundleID,
          onUseSelectedApp: onUseSelectedApp
        )

        HStack {
          Spacer()

          Button {
            onApply()
          } label: {
            ToolButtonLabel(
              title: isRunning ? "Applying" : "Apply",
              systemImage: "checkmark.shield",
              isRunning: isRunning
            )
          }
          .disabled(disabledReason != nil)
          .help(disabledReason ?? "Apply privacy permission")
        }

        ToolStatusText(disabledReason)
      }
    }
  }
}
