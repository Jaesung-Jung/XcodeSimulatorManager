import SwiftUI

extension DeveloperToolsView {
  struct StatusBarOverridePanel: View {
    @Binding var time: String
    @Binding var dataNetwork: DeveloperToolsFeature.StatusBarDataNetwork?
    @Binding var wifiMode: DeveloperToolsFeature.StatusBarWifiMode?
    @Binding var wifiBars: String
    @Binding var cellularMode: DeveloperToolsFeature.StatusBarCellularMode?
    @Binding var cellularBars: String
    @Binding var operatorNameIncluded: Bool
    @Binding var operatorName: String
    @Binding var batteryState: DeveloperToolsFeature.StatusBarBatteryState?
    @Binding var batteryLevel: String

    let disabledReason: String?
    let clearDisabledReason: String?
    let isApplyRunning: Bool
    let isClearRunning: Bool
    let onApply: () -> Void
    let onClear: () -> Void

    var body: some View {
      ToolPanel {
        TextField("Time or ISO Date", text: $time)
          .textFieldStyle(.roundedBorder)

        HStack(spacing: 8) {
          Picker("Data Network", selection: $dataNetwork) {
            Text("No Data Network")
              .tag(DeveloperToolsFeature.StatusBarDataNetwork?.none)
            ForEach(DeveloperToolsFeature.StatusBarDataNetwork.allCases) { dataNetwork in
              Text(dataNetwork.displayTitle)
                .tag(DeveloperToolsFeature.StatusBarDataNetwork?.some(dataNetwork))
            }
          }
          .pickerStyle(.menu)

          Picker("Wi-Fi Mode", selection: $wifiMode) {
            Text("No Wi-Fi Mode")
              .tag(DeveloperToolsFeature.StatusBarWifiMode?.none)
            ForEach(DeveloperToolsFeature.StatusBarWifiMode.allCases) { wifiMode in
              Text(wifiMode.displayTitle)
                .tag(DeveloperToolsFeature.StatusBarWifiMode?.some(wifiMode))
            }
          }
          .pickerStyle(.menu)
        }

        HStack(spacing: 8) {
          TextField("Wi-Fi Bars 0-3", text: $wifiBars)
            .textFieldStyle(.roundedBorder)

          Picker("Cellular Mode", selection: $cellularMode) {
            Text("No Cellular Mode")
              .tag(DeveloperToolsFeature.StatusBarCellularMode?.none)
            ForEach(DeveloperToolsFeature.StatusBarCellularMode.allCases) { cellularMode in
              Text(cellularMode.displayTitle)
                .tag(DeveloperToolsFeature.StatusBarCellularMode?.some(cellularMode))
            }
          }
          .pickerStyle(.menu)
        }

        HStack(spacing: 8) {
          TextField("Cellular Bars 0-4", text: $cellularBars)
            .textFieldStyle(.roundedBorder)

          Toggle("Operator Name", isOn: $operatorNameIncluded)
            .toggleStyle(.checkbox)
        }

        if operatorNameIncluded {
          TextField("Carrier name", text: $operatorName)
            .textFieldStyle(.roundedBorder)
        }

        HStack(spacing: 8) {
          Picker("Battery State", selection: $batteryState) {
            Text("No Battery State")
              .tag(DeveloperToolsFeature.StatusBarBatteryState?.none)
            ForEach(DeveloperToolsFeature.StatusBarBatteryState.allCases) { batteryState in
              Text(batteryState.displayTitle)
                .tag(DeveloperToolsFeature.StatusBarBatteryState?.some(batteryState))
            }
          }
          .pickerStyle(.menu)

          TextField("Battery Level 0-100", text: $batteryLevel)
            .textFieldStyle(.roundedBorder)
        }

        HStack(spacing: 8) {
          Spacer()

          Button {
            onClear()
          } label: {
            ToolButtonLabel(
              title: isClearRunning ? "Clearing" : "Clear",
              systemImage: "xmark.circle",
              isRunning: isClearRunning
            )
          }
          .disabled(clearDisabledReason != nil)
          .help(clearDisabledReason ?? "Clear status bar overrides")

          Button {
            onApply()
          } label: {
            ToolButtonLabel(
              title: isApplyRunning ? "Applying" : "Apply",
              systemImage: "iphone.gen3.radiowaves.left.and.right",
              isRunning: isApplyRunning
            )
          }
          .disabled(disabledReason != nil)
          .help(disabledReason ?? "Apply status bar overrides")
        }

        ToolStatusText(disabledReason ?? clearDisabledReason)
      }
    }
  }
}

// MARK: - StatusBarOverridePanel Preview

#if DEBUG

#Preview {
  DeveloperToolsView.StatusBarOverridePanel(
    time: .constant("9:41"),
    dataNetwork: .constant(.wifi),
    wifiMode: .constant(.active),
    wifiBars: .constant("3"),
    cellularMode: .constant(.active),
    cellularBars: .constant("4"),
    operatorNameIncluded: .constant(true),
    operatorName: .constant("Preview"),
    batteryState: .constant(.charged),
    batteryLevel: .constant("100"),
    disabledReason: nil,
    clearDisabledReason: nil,
    isApplyRunning: false,
    isClearRunning: false,
    onApply: {},
    onClear: {}
  )
  .padding(20)
  .frame(width: 480)
}

#endif
