# Environment with Observation

## Intent

Use `environment(_:)` and `@Environment(Type.self)` on iOS 17+ when a dependency or shared model truly belongs to a broad section of the app.

## Core rules

- Use the environment for shared services, routers, theme/configuration, or models needed by many descendants.
- Prefer explicit initializer injection for feature-local dependencies and models.
- Inject observable reference types with `.environment(someModel)` and read them with `@Environment(SomeModel.self)`.
- Keep mutable feature state out of the environment unless sharing that state is intentional.
- On iOS 16 and earlier, fall back to `environmentObject(_:)` and `@EnvironmentObject` only when Observation is unavailable.

## Example

```swift
@MainActor
@Observable
final class AppSettings {
  var isDarkMode = false
  var preferredFont = "System"
}

@main
struct ReadinApp: App {
  @State private var settings = AppSettings()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(settings)
    }
  }
}

struct SettingsView: View {
  @Environment(AppSettings.self) private var settings

  var body: some View {
    Toggle("Dark Mode", isOn: $settings.isDarkMode)
  }
}
```

## When to avoid it

- A dependency is only used by one feature or one screen subtree.
- The type represents feature-local editing state better passed through an initializer.
- The environment would hide critical ownership or make testing less explicit.

## Pitfalls

- Using the environment as a grab bag for unrelated feature state.
- Mixing `@EnvironmentObject` with `@Observable` in new iOS 17+ code.
- Assuming environment injection removes the need to define ownership clearly.
