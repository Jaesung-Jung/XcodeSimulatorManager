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
