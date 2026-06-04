import SwiftUI

extension InstalledAppsView {
  struct AppIconView: View {
    let iconPath: URL?

    private var iconImage: NSImage? {
      guard let iconPath else {
        return nil
      }

      return NSImage(contentsOf: iconPath)
    }

    var body: some View {
      Group {
        if let iconImage {
          Image(nsImage: iconImage)
            .resizable()
        } else {
          Image(.appIconTemplate)
            .resizable()
        }
      }
      .scaledToFit()
      .frame(width: 48, height: 48)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .accessibilityHidden(true)
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
