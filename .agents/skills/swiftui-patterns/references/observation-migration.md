# Observation migration

## Intent

Use this checklist before converting legacy SwiftUI code from `ObservableObject` to the Observation framework.

## Checklist

- Replace `ObservableObject` with `@Observable` where the deployment target allows it.
- Remove `@Published`; stored properties are observed automatically.
- Replace `@StateObject` with `@State` when the view owns an `@Observable` model.
- Replace `@ObservedObject` with a stored property, and add `@Bindable` only if the child view needs bindings.
- Replace `environmentObject(_:)` with `environment(_:)`.
- Replace `@EnvironmentObject` with `@Environment(Type.self)`.
- Replace `.onAppear { Task { ... } }` with `.task`.
- Update `onChange(of:perform:)` to `onChange(of:initial:_:)` when you need modern change handling.
- Confirm that the model still has a single clear owner after the migration.

## Before

```swift
final class UserProfileModel: ObservableObject {
  @Published var name = ""
  @Published var email = ""

  @MainActor
  func load() async {}
}

struct ProfileView: View {
  @StateObject private var model = UserProfileModel()

  var body: some View {
    TextField("Name", text: $model.name)
      .onAppear {
        Task {
          await model.load()
        }
      }
  }
}
```

## After

```swift
@MainActor
@Observable
final class UserProfileModel {
  var name = ""
  var email = ""

  func load() async {}
}

struct ProfileView: View {
  @State private var model = UserProfileModel()

  var body: some View {
    TextField("Name", text: $model.name)
      .task {
        await model.load()
      }
  }
}
```

## Watch for mixed patterns

- Do not keep `@Published` after moving to `@Observable`.
- Do not leave `@StateObject` or `@ObservedObject` in place for the migrated model.
- Do not convert shared feature state to the environment unless that was already the intended ownership.
