# Coding Styles

This document records project-local coding conventions. Follow these rules before adding new style or structure.

## SwiftUI View Structure

Order members inside a `View` type in this sequence:

1. Mutable stored properties: `@State`, `@Binding`, `@FocusState`, mutable `var`
2. Immutable stored properties: `let`
3. Read-only computed properties that return non-view values
4. `init`
5. `body`
6. Non-view helper functions

Example:

```swift
struct ExampleView: View {
  @State private var isExpanded = false

  let title: String
  let count: Int

  private var countTitle: String {
    "\(count)"
  }

  init(title: String, count: Int) {
    self.title = title
    self.count = count
  }

  var body: some View {
    VStack {
      Text(title)
      Text(countTitle)
    }
  }

  private func toggle() {
    isExpanded.toggle()
  }
}
```

## Nested SwiftUI Views

Use nested `View` types for meaningful UI pieces that belong only to one parent view.

- Put nested views in an `extension ParentView`.
- Keep one nested `View` type per extension.
- Mark nested views `private` unless another file must use them.
- Give nested views explicit, minimal input properties.
- Do not pass a whole TCA store to a nested view unless the nested view needs scoped state/actions.
- Nested views follow the same member ordering as top-level views.

Example:

```swift
extension ParentView {
  private struct SummaryRow: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
      HStack {
        Text(title)
        Spacer()
        Text(value)
      }
    }
  }
}
```

## View Helper Functions

Do not use private functions or computed properties to build separable view sections.

Avoid:

```swift
private func metricsGrid(device: SimulatorDevice) -> some View {
  LazyVGrid {
    // Many child views
  }
}
```

Prefer:

```swift
MetricsGrid(device: device)
```

with:

```swift
extension DeviceDetailView {
  private struct MetricsGrid: View {
    let device: SimulatorDevice

    var body: some View {
      LazyVGrid {
        // Many child views
      }
    }
  }
}
```

Small non-view helpers are fine when they calculate values or perform local actions. If a helper returns `some View`, first try to make it a nested `View`.

## Read-Only Properties

Read-only computed properties should sit above `init` and `body`.

Use them for display strings, bindings, counts, booleans, and other non-view values:

```swift
private var isRefreshing: Bool {
  store.workspace.refreshState == .refreshing
}
```

Do not use read-only computed properties for view fragments:

```swift
private var header: some View { ... }
```

Create a nested `View` instead.

## File Boundaries

For `Features/MainWindow`, keep the root folder organized by responsibility:

- `Features/`: reducers and feature state
- `Features/State/`: feature-local shared state types
- `Views/`: top-level views for the feature
- `Views/Support/`: view-only display extensions and formatting values
- `Views/Previews/`: preview fixtures and preview-only stores

Keep app-wide reusable view primitives under `SharedUI`. Views used by only one parent should stay nested under that parent, not in `SharedUI`.

## Naming

- Use `UpperCamelCase` for types and `lowerCamelCase` for properties/functions.
- Avoid abbreviations except common forms such as `URL`, `ID`, and `UUID`.
- Prefer names that describe the UI role: `MetricsGrid`, `CommandResultRow`, `InitialStateContent`.
- Avoid generic names such as `Helper`, `Manager`, or `ViewBuilder`.

## SwiftUI/AppKit Boundary

Prefer SwiftUI semantic APIs over AppKit color/view bridges in SwiftUI views.

Use:

```swift
.background(.windowBackground)
.background(.background)
```

Avoid:

```swift
.background(Color(nsColor: .windowBackgroundColor))
```

AppKit is acceptable at app lifecycle boundaries, such as `AppDelegate`, when SwiftUI does not provide the needed behavior directly.
