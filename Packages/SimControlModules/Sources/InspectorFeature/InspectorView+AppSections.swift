import ComposableArchitecture
import SimControlDomain
import SwiftUI

// MARK: - InspectorView.SelectedAppSection

extension InspectorView {
  struct SelectedAppSection: View {
    let store: StoreOf<InspectorFeature>
    let selectedApp: InstalledApp

    var body: some View {
      InspectorSection("Selected App") {
        FieldRow(title: "Name", value: selectedApp.displayName)
        FieldRow(
          title: "Bundle ID",
          value: selectedApp.bundleID,
          onCopy: {
            store.send(.copyAppBundleIDButtonTapped(selectedApp.id))
          }
        )
        FieldRow(title: "Version", value: selectedApp.version)
        FieldRow(title: "Build", value: selectedApp.build)
        FieldRow(
          title: "Bundle Container",
          value: selectedApp.bundleContainer?.path,
          onOpen: {
            store.send(.openAppBundleContainerButtonTapped(selectedApp.id))
          },
          onCopy: {
            store.send(.copyAppBundleContainerButtonTapped(selectedApp.id))
          }
        )
        FieldRow(
          title: "Data Container",
          value: selectedApp.dataContainer?.path,
          onOpen: {
            store.send(.openAppDataContainerButtonTapped(selectedApp.id))
          },
          onCopy: {
            store.send(.copyAppDataContainerButtonTapped(selectedApp.id))
          }
        )
      }
    }
  }
}

// MARK: - InspectorView.SelectedAppSection Preview

#if DEBUG

#Preview {
  let app = InstalledApp(
    id: "PREVIEW-DEVICE-1:com.example.preview",
    bundleID: "com.example.preview",
    displayName: "Preview App",
    version: "1.0",
    build: "100",
    deviceID: "PREVIEW-DEVICE-1",
    bundleContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle"),
    dataContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Data"),
    appBundlePath: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle/Preview.app"),
    appGroups: [
      AppGroupContainer(
        id: "group.com.example.preview",
        groupID: "group.com.example.preview",
        path: URL(fileURLWithPath: "/tmp/PreviewApp/Groups/group.com.example.preview")
      )
    ],
    iconPath: nil
  )

  VStack(alignment: .leading, spacing: 18) {
    InspectorView.SelectedAppSection(
      store: Store(initialState: InspectorFeature.State(selectedApp: app)) {
        InspectorFeature()
      },
      selectedApp: app
    )

    InspectorView.AppGroupsSection(
      store: Store(initialState: InspectorFeature.State(selectedApp: app)) {
        InspectorFeature()
      },
      selectedApp: app
    )
  }
  .padding(20)
  .frame(width: 360)
}

#endif

// MARK: - InspectorView.AppGroupsSection

extension InspectorView {
  struct AppGroupsSection: View {
    let store: StoreOf<InspectorFeature>
    let selectedApp: InstalledApp

    var body: some View {
      InspectorSection("App Groups") {
        ForEach(selectedApp.appGroups) { appGroup in
          FieldRow(
            title: LocalizedStringKey(appGroup.groupID),
            value: appGroup.path.path,
            onOpen: {
              store.send(.openAppGroupContainerButtonTapped(selectedApp.id, appGroup.groupID))
            },
            onCopy: {
              store.send(.copyAppGroupContainerButtonTapped(selectedApp.id, appGroup.groupID))
            }
          )
        }
      }
    }
  }
}
