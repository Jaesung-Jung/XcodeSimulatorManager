import ComposableArchitecture
import MainWindowDisplaySupport
import SimControlDomain
import SwiftUI

// MARK: - InspectorView.DeviceSection

extension InspectorView {
  struct DeviceSection: View {
    let store: StoreOf<InspectorFeature>
    let device: SimulatorDevice

    var body: some View {
      InspectorSection("Device") {
        FieldRow(title: "Name", value: device.name)
        FieldRow(
          title: "UDID",
          value: device.udid,
          onCopy: {
            store.send(.copyDeviceUDIDButtonTapped(device.id))
          }
        )
        FieldRow(title: "State", value: device.state.displayTitle)
        FieldRow(title: "Runtime", value: store.runtime?.name ?? device.runtimeID)
        FieldRow(
          title: "Runtime ID",
          value: device.runtimeID,
          onCopy: {
            store.send(.copyRuntimeIdentifierButtonTapped(device.id))
          }
        )
        FieldRow(title: "Device Type", value: store.deviceType?.name ?? device.deviceTypeID)
        FieldRow(
          title: "Device Type ID",
          value: device.deviceTypeID,
          onCopy: {
            store.send(.copyDeviceTypeIdentifierButtonTapped(device.id))
          }
        )
        FieldRow(
          title: "Availability",
          value: device.availabilityTitle
        )
      }
    }
  }
}

// MARK: - InspectorView.DeviceSection Preview

#if DEBUG

#Preview {
  let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: []
  )
  let deviceType = SimulatorDeviceType(
    id: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )
  let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: runtime.id,
    deviceTypeID: deviceType.id,
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/tmp/PreviewDevice/data"),
    logPath: URL(fileURLWithPath: "/tmp/PreviewDevice/logs"),
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )
  let store = Store(
    initialState: InspectorFeature.State(
      device: device,
      runtime: runtime,
      deviceType: deviceType
    )
  ) {
    InspectorFeature()
  }

  VStack(alignment: .leading, spacing: 18) {
    InspectorView.DeviceSection(store: store, device: device)
    InspectorView.DeviceFoldersSection(store: store, device: device)
  }
  .padding(20)
  .frame(width: 360)
}

#endif

// MARK: - InspectorView.DeviceFoldersSection

extension InspectorView {
  struct DeviceFoldersSection: View {
    let store: StoreOf<InspectorFeature>
    let device: SimulatorDevice

    var body: some View {
      InspectorSection("Folders") {
        FieldRow(
          title: "Data",
          value: device.dataPath?.path,
          onOpen: {
            store.send(.openDeviceDataFolderButtonTapped(device.id))
          },
          onCopy: {
            store.send(.copyDeviceDataPathButtonTapped(device.id))
          }
        )
        FieldRow(
          title: "Logs",
          value: device.logPath?.path,
          onOpen: {
            store.send(.openDeviceLogFolderButtonTapped(device.id))
          },
          onCopy: {
            store.send(.copyDeviceLogPathButtonTapped(device.id))
          }
        )
      }
    }
  }
}
