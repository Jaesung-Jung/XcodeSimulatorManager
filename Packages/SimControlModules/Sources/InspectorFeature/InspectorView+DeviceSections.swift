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
