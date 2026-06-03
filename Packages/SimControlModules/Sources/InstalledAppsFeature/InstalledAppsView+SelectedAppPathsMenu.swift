import SimControlDomain
import SwiftUI

extension InstalledAppsView {
  struct SelectedAppPathsMenu: View {
    let app: InstalledApp
    let canUsePaths: Bool
    let onOpenBundleContainer: () -> Void
    let onCopyBundleContainer: () -> Void
    let onOpenDataContainer: () -> Void
    let onCopyDataContainer: () -> Void
    let onCopyBundleID: () -> Void
    let onOpenAppGroup: (String) -> Void
    let onCopyAppGroup: (String) -> Void

    var body: some View {
      Menu {
        Button {
          onOpenBundleContainer()
        } label: {
          Label("Open Bundle Container", systemImage: "folder")
        }

        Button {
          onCopyBundleContainer()
        } label: {
          Label("Copy Bundle Container Path", systemImage: "doc.on.doc")
        }

        Button {
          onOpenDataContainer()
        } label: {
          Label("Open Data Container", systemImage: "folder")
        }

        Button {
          onCopyDataContainer()
        } label: {
          Label("Copy Data Container Path", systemImage: "doc.on.doc")
        }

        Divider()

        Button {
          onCopyBundleID()
        } label: {
          Label("Copy Bundle Identifier", systemImage: "doc.on.doc")
        }

        if !app.appGroups.isEmpty {
          Divider()

          ForEach(app.appGroups) { appGroup in
            Menu {
              Button {
                onOpenAppGroup(appGroup.groupID)
              } label: {
                Label("Open Container", systemImage: "folder")
              }

              Button {
                onCopyAppGroup(appGroup.groupID)
              } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
              }
            } label: {
              Label(appGroup.groupID, systemImage: "person.2.crop.square.stack")
            }
          }
        }
      } label: {
        ActionButtonLabel(
          title: "Paths",
          systemImage: "folder",
          isRunning: false
        )
      }
      .disabled(!canUsePaths)
    }
  }
}
