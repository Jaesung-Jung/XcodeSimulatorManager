import SwiftUI

extension DeveloperToolsView {
  struct LocationPanel: View {
    @Binding var preset: DeveloperToolsFeature.LocationPreset
    @Binding var customLatitude: String
    @Binding var customLongitude: String

    let recentLocations: [DeveloperToolsFeature.LocationCoordinateInput]
    let disabledReason: String?
    let clearDisabledReason: String?
    let isSetRunning: Bool
    let isClearRunning: Bool
    let onRecentSelected: (DeveloperToolsFeature.LocationCoordinateInput) -> Void
    let onSet: () -> Void
    let onClear: () -> Void

    var body: some View {
      ToolPanel(title: "Location", systemImage: "location") {
        HStack(spacing: 8) {
          Picker("Preset", selection: $preset) {
            ForEach(DeveloperToolsFeature.LocationPreset.allCases) { preset in
              Text(preset.displayTitle)
                .tag(preset)
            }
          }
          .pickerStyle(.menu)

          if !recentLocations.isEmpty {
            Menu {
              ForEach(recentLocations) { location in
                Button("\(location.latitude), \(location.longitude)") {
                  onRecentSelected(location)
                }
              }
            } label: {
              Label("Recent", systemImage: "clock.arrow.circlepath")
            }
          }
        }

        if preset == .custom {
          HStack(spacing: 8) {
            TextField("Latitude", text: $customLatitude)
              .textFieldStyle(.roundedBorder)

            TextField("Longitude", text: $customLongitude)
              .textFieldStyle(.roundedBorder)
          }
        }

        HStack(spacing: 8) {
          Spacer()

          Button {
            onClear()
          } label: {
            ToolButtonLabel(
              title: isClearRunning ? "Clearing" : "Clear",
              systemImage: "location.slash",
              isRunning: isClearRunning
            )
          }
          .disabled(clearDisabledReason != nil)
          .help(clearDisabledReason ?? "Clear simulated location")

          Button {
            onSet()
          } label: {
            ToolButtonLabel(
              title: isSetRunning ? "Setting" : "Set",
              systemImage: "location.fill",
              isRunning: isSetRunning
            )
          }
          .disabled(disabledReason != nil)
          .help(disabledReason ?? "Set simulated location")
        }

        ToolStatusText(disabledReason ?? clearDisabledReason)
      }
    }
  }
}
