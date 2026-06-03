# State ownership

## Intent

Choose the narrowest state tool that matches the ownership model before writing the UI.

## Ownership matrix

| Scenario | Preferred pattern |
| --- | --- |
| Local value state owned by one view | `@State` |
| Child mutates parent-owned value state | `@Binding` |
| Root-owned reference model on iOS 17+ | `@State` with an `@Observable` type |
| Child mutates an injected `@Observable` model | `@Bindable` |
| Shared app service or configuration | `@Environment(Type.self)` |
| Legacy reference model on iOS 16 and earlier | `@StateObject` at the root, `@ObservedObject` when injected |

## Example: local view state

```swift
struct ReaderControls: View {
  @State private var isShowingChapters = false

  var body: some View {
    Button("Chapters") {
      isShowingChapters.toggle()
    }
    .sheet(isPresented: $isShowingChapters) {
      ChapterListView()
    }
  }
}
```

## Example: root-owned reference model

```swift
@MainActor
@Observable
final class ReaderSettingsModel {
  var fontScale: Double = 1.0
  var lineSpacing: Double = 1.2
}

struct ReaderSettingsScreen: View {
  @State private var model = ReaderSettingsModel()

  var body: some View {
    ReaderSettingsForm(model: model)
  }
}

struct ReaderSettingsForm: View {
  @Bindable var model: ReaderSettingsModel

  var body: some View {
    Form {
      Slider(value: $model.fontScale, in: 0.8 ... 1.6)
      Slider(value: $model.lineSpacing, in: 1.0 ... 2.0)
    }
  }
}
```

## Selection rules

- Decide ownership first, then pick the property wrapper.
- Prefer value state until you need shared mutation, lifecycle-driven async logic, or reference semantics.
- Keep ephemeral presentation flags close to the view even when the feature also has an observable model.
- Do not move feature-local state into the environment just to avoid passing one or two arguments.

## Pitfalls

- Using `@StateObject` for `@Observable` types.
- Promoting local state into a shared reference model without a real ownership need.
- Passing bindings through many layers when a small wrapper view would be clearer.
