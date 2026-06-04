import SwiftUI

extension InstalledAppsView {
  struct AppIconView: View {
    let iconPath: URL?
    @State private var iconImage: NSImage?

    var body: some View {
      image
      .resizable()
      .scaledToFit()
      .frame(width: 48, height: 48)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .accessibilityHidden(true)
      .task(id: iconPath) {
        await loadIcon()
      }
    }

    private var image: Image {
      if let iconImage {
        Image(nsImage: iconImage)
      } else {
        Image("AppIconTemplate", bundle: .module)
      }
    }

    @MainActor private func loadIcon() async {
      iconImage = nil
      iconImage = await AppIconImageLoader.shared.image(for: iconPath)
    }
  }
}

// MARK: - InstalledAppsView.AppIconView Preview

#if DEBUG

#Preview {
  HStack(spacing: 16) {
    InstalledAppsView.AppIconView(iconPath: nil)
      .environment(\.colorScheme, .light)

    InstalledAppsView.AppIconView(iconPath: nil)
      .environment(\.colorScheme, .dark)
  }
  .padding(20)
}

#endif
