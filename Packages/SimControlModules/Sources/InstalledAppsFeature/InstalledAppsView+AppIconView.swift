import SimControlDomain
import SwiftUI

extension InstalledAppsView {
  struct AppIconView: View {
    enum IconShapeKind: Equatable {
      case roundedRectangle
      case circle
    }

    let iconPath: URL?
    let appBundlePath: URL?
    let bundleID: String
    let displayName: String
    let platform: SimulatorPlatform?
    let deviceTypeID: String?
    @State private var iconImage: NSImage?

    init(
      iconPath: URL?,
      appBundlePath: URL? = nil,
      bundleID: String = "",
      displayName: String = "",
      platform: SimulatorPlatform? = nil,
      deviceTypeID: String? = nil
    ) {
      self.iconPath = iconPath
      self.appBundlePath = appBundlePath
      self.bundleID = bundleID
      self.displayName = displayName
      self.platform = platform
      self.deviceTypeID = deviceTypeID
    }

    var body: some View {
      clippedImage
      .accessibilityHidden(true)
      .task(id: iconRequest) {
        await loadIcon()
      }
    }

    private var iconRequest: AppIconImageLoader.Request {
      AppIconImageLoader.Request(
        iconPath: iconPath,
        appBundlePath: appBundlePath,
        bundleID: bundleID,
        displayName: displayName,
        platform: platform,
        deviceTypeID: deviceTypeID
      )
    }

    @ViewBuilder private var clippedImage: some View {
      switch Self.iconShapeKind(for: platform) {
      case .roundedRectangle:
        imageContent
          .clipShape(.rect(cornerRadius: 12, style: .continuous))
      case .circle:
        imageContent
          .clipShape(.circle)
      }
    }

    private var imageContent: some View {
      image
        .resizable()
        .scaledToFit()
        .frame(width: 48, height: 48)
    }

    private var image: Image {
      if let iconImage {
        Image(nsImage: iconImage)
      } else {
        Image("AppIconTemplate", bundle: .module)
      }
    }

    static func iconShapeKind(for platform: SimulatorPlatform?) -> IconShapeKind {
      switch platform {
      case .watchOS, .visionOS:
        .circle
      case .iOS, .tvOS, .unknown, .none:
        .roundedRectangle
      }
    }

    @MainActor private func loadIcon() async {
      iconImage = nil
      iconImage = await AppIconImageLoader.shared.image(for: iconRequest)
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

    InstalledAppsView.AppIconView(iconPath: nil, platform: .watchOS)
      .environment(\.colorScheme, .dark)
  }
  .padding(20)
}

#endif
