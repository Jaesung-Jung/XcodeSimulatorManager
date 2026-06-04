# Installed App Icons Design

## Goal

Installed Apps rows should show each installed app's real icon when an icon file is available. If the real icon is missing or cannot be loaded, the row should show the provided fallback template image that matches the current Light or Dark appearance.

## Approach

Use the existing `InstalledApp.iconPath` value as the primary source. `InstalledAppsView.AppRow` will replace the fixed SF Symbol with a small SwiftUI icon view that attempts to load `NSImage(contentsOf:)` from `iconPath`.

Fallback images will live in the `InstalledAppsFeature` package resources:

- `AppIconTemplateLight.png`
- `AppIconTemplateDark.png`

The fallback view chooses the image from `colorScheme`.

## UI Behavior

Each row keeps a stable icon frame so row layout does not shift between real and fallback icons. Icons are decorative inside the already-combined row accessibility element, so they remain accessibility-hidden.

## Error Handling

Missing `iconPath`, unreadable files, unsupported image data, and missing fallback resources all degrade without crashing. If both real and fallback images are unavailable, the view falls back to the existing `app` SF Symbol.

## Testing

Add focused SwiftUI build coverage for the new icon view states and keep existing scanner tests that verify `InstalledApp.iconPath` is populated from app bundle metadata. Verify the `InstalledAppsFeature` target builds with package resources.
