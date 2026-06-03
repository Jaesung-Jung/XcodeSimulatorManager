import ComposableArchitecture
import SimControlDomain
import SwiftUI

struct DeveloperToolsView: View {
  let store: StoreOf<DeveloperToolsFeature>

  private var deepLinkURLString: Binding<String> {
    Binding(
      get: { store.deepLinkURLString },
      set: { store.send(.deepLinkURLChanged($0)) }
    )
  }

  private var pushBundleID: Binding<String> {
    Binding(
      get: { store.pushBundleID },
      set: { store.send(.pushBundleIDChanged($0)) }
    )
  }

  private var pushPayloadJSON: Binding<String> {
    Binding(
      get: { store.pushPayloadJSON },
      set: { store.send(.pushPayloadJSONChanged($0)) }
    )
  }

  private var privacyAction: Binding<DeveloperToolsFeature.PrivacyAction> {
    Binding(
      get: { store.privacyAction },
      set: { store.send(.privacyActionChanged($0)) }
    )
  }

  private var privacyBundleID: Binding<String> {
    Binding(
      get: { store.privacyBundleID },
      set: { store.send(.privacyBundleIDChanged($0)) }
    )
  }

  private var locationPreset: Binding<DeveloperToolsFeature.LocationPreset> {
    Binding(
      get: { store.locationPreset },
      set: { store.send(.locationPresetChanged($0)) }
    )
  }

  private var customLatitude: Binding<String> {
    Binding(
      get: { store.customLatitude },
      set: { store.send(.customLatitudeChanged($0)) }
    )
  }

  private var customLongitude: Binding<String> {
    Binding(
      get: { store.customLongitude },
      set: { store.send(.customLongitudeChanged($0)) }
    )
  }

  private var statusBarTime: Binding<String> {
    Binding(
      get: { store.statusBarTime },
      set: { store.send(.statusBarTimeChanged($0)) }
    )
  }

  private var statusBarDataNetwork: Binding<DeveloperToolsFeature.StatusBarDataNetwork?> {
    Binding(
      get: { store.statusBarDataNetwork },
      set: { store.send(.statusBarDataNetworkChanged($0)) }
    )
  }

  private var statusBarWifiMode: Binding<DeveloperToolsFeature.StatusBarWifiMode?> {
    Binding(
      get: { store.statusBarWifiMode },
      set: { store.send(.statusBarWifiModeChanged($0)) }
    )
  }

  private var statusBarWifiBars: Binding<String> {
    Binding(
      get: { store.statusBarWifiBars },
      set: { store.send(.statusBarWifiBarsChanged($0)) }
    )
  }

  private var statusBarCellularMode: Binding<DeveloperToolsFeature.StatusBarCellularMode?> {
    Binding(
      get: { store.statusBarCellularMode },
      set: { store.send(.statusBarCellularModeChanged($0)) }
    )
  }

  private var statusBarCellularBars: Binding<String> {
    Binding(
      get: { store.statusBarCellularBars },
      set: { store.send(.statusBarCellularBarsChanged($0)) }
    )
  }

  private var statusBarOperatorNameIncluded: Binding<Bool> {
    Binding(
      get: { store.statusBarOperatorNameIncluded },
      set: { store.send(.statusBarOperatorNameIncludedChanged($0)) }
    )
  }

  private var statusBarOperatorName: Binding<String> {
    Binding(
      get: { store.statusBarOperatorName },
      set: { store.send(.statusBarOperatorNameChanged($0)) }
    )
  }

  private var statusBarBatteryState: Binding<DeveloperToolsFeature.StatusBarBatteryState?> {
    Binding(
      get: { store.statusBarBatteryState },
      set: { store.send(.statusBarBatteryStateChanged($0)) }
    )
  }

  private var statusBarBatteryLevel: Binding<String> {
    Binding(
      get: { store.statusBarBatteryLevel },
      set: { store.send(.statusBarBatteryLevelChanged($0)) }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader(title: "Developer Tools", systemImage: "wrench.and.screwdriver")

      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 280), spacing: 10)
        ],
        alignment: .leading,
        spacing: 10
      ) {
        DeepLinkPanel(
          urlString: deepLinkURLString,
          recentURLs: store.recentDeepLinkURLs,
          disabledReason: store.openDeepLinkDisabledReason,
          isRunning: isRunning(.openURL),
          onRecentSelected: { urlString in
            store.send(.recentDeepLinkURLSelected(urlString))
          },
          onOpen: {
            store.send(.openDeepLinkButtonTapped)
          }
        )

        PushPanel(
          bundleID: pushBundleID,
          payloadJSON: pushPayloadJSON,
          bundleIDOptions: store.appBundleIDOptions,
          selectedAppBundleID: store.selectedAppBundleID,
          disabledReason: store.sendPushDisabledReason,
          isRunning: isRunning(.pushNotification),
          onUseSelectedApp: {
            store.send(.useSelectedAppBundleButtonTapped)
          },
          onSend: {
            store.send(.sendPushButtonTapped)
          }
        )

        PrivacyPanel(
          action: privacyAction,
          bundleID: privacyBundleID,
          service: store.privacyService,
          bundleIDOptions: store.appBundleIDOptions,
          selectedAppBundleID: store.selectedAppBundleID,
          disabledReason: store.applyPrivacyDisabledReason,
          isRunning: isRunning(.privacyPermission),
          onServiceSelected: { service in
            store.send(.privacyServiceChanged(service))
          },
          onUseSelectedApp: {
            store.send(.useSelectedAppBundleButtonTapped)
          },
          onApply: {
            store.send(.applyPrivacyButtonTapped)
          }
        )

        LocationPanel(
          preset: locationPreset,
          customLatitude: customLatitude,
          customLongitude: customLongitude,
          recentLocations: store.recentLocations,
          disabledReason: store.setLocationDisabledReason,
          clearDisabledReason: store.clearLocationDisabledReason,
          isSetRunning: isRunning(.setLocation),
          isClearRunning: isRunning(.clearLocation),
          onRecentSelected: { location in
            store.send(.recentLocationSelected(location))
          },
          onSet: {
            store.send(.setLocationButtonTapped)
          },
          onClear: {
            store.send(.clearLocationButtonTapped)
          }
        )

        StatusBarOverridePanel(
          time: statusBarTime,
          dataNetwork: statusBarDataNetwork,
          wifiMode: statusBarWifiMode,
          wifiBars: statusBarWifiBars,
          cellularMode: statusBarCellularMode,
          cellularBars: statusBarCellularBars,
          operatorNameIncluded: statusBarOperatorNameIncluded,
          operatorName: statusBarOperatorName,
          batteryState: statusBarBatteryState,
          batteryLevel: statusBarBatteryLevel,
          disabledReason: store.setStatusBarOverrideDisabledReason,
          clearDisabledReason: store.clearStatusBarOverrideDisabledReason,
          isApplyRunning: isRunning(.statusBarOverride),
          isClearRunning: isRunning(.clearStatusBarOverride),
          onApply: {
            store.send(.setStatusBarOverrideButtonTapped)
          },
          onClear: {
            store.send(.clearStatusBarOverrideButtonTapped)
          }
        )
      }
    }
  }

  private func isRunning(_ command: DeviceCommand) -> Bool {
    store.deviceCommandState?.command == command
  }
}

extension DeveloperToolsView {
  private struct DeepLinkPanel: View {
    @Binding var urlString: String

    let recentURLs: [String]
    let disabledReason: String?
    let isRunning: Bool
    let onRecentSelected: (String) -> Void
    let onOpen: () -> Void

    var body: some View {
      ToolPanel(title: "Deep Link", systemImage: "link") {
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

extension DeveloperToolsView {
  private struct PushPanel: View {
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

extension DeveloperToolsView {
  private struct PrivacyPanel: View {
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

extension DeveloperToolsView {
  private struct LocationPanel: View {
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

extension DeveloperToolsView {
  private struct StatusBarOverridePanel: View {
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
      ToolPanel(title: "Status Bar Override", systemImage: "rectangle.topthird.inset.filled") {
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

extension DeveloperToolsView {
  private struct ToolPanel<Content: View>: View {
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
      VStack(alignment: .leading, spacing: 8) {
        Label(title, systemImage: systemImage)
          .font(.subheadline.weight(.medium))
          .lineLimit(1)

        content()
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }
  }
}

extension DeveloperToolsView {
  private struct BundleIDRow: View {
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
  private struct ServiceMenu: View {
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
  private struct ToolButtonLabel: View {
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
  private struct ToolStatusText: View {
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

#if DEBUG

#Preview {
  DeveloperToolsView(
    store: Store(
      initialState: DeveloperToolsFeature.State(
        device: MainWindowPreviewFixtures.device,
        installedApps: [MainWindowPreviewFixtures.app],
        selectedAppID: MainWindowPreviewFixtures.app.id
      )
    ) {
      DeveloperToolsFeature()
    }
  )
  .padding(20)
  .frame(width: 720)
}

#endif
