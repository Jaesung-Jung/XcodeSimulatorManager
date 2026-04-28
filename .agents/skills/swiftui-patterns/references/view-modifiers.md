# Modern view modifiers

## Intent

Use current SwiftUI lifecycle and change-observation modifiers instead of older `onAppear` and deprecated `onChange` patterns.

## `onChange(of:initial:_:)`

Use the modern signature when change handling needs both old and new values, or when the work should also run on first appearance.

```swift
struct SearchView: View {
  @State private var query = ""

  var body: some View {
    TextField("Search", text: $query)
      .onChange(of: query) { oldValue, newValue in
        guard oldValue != newValue else { return }
        validate(newValue)
      }
      .onChange(of: query, initial: true) { _, newValue in
        preloadSuggestions(for: newValue)
      }
  }
}
```

## `.task` and `.task(id:)`

Use `.task` for work tied to the view lifecycle, and `.task(id:)` when the work should cancel and restart for changing input.

```swift
struct UserListView: View {
  let selectedFilter: UserFilter
  @State private var users: [User] = []

  var body: some View {
    List(users) { user in
      Text(user.name)
    }
    .task(id: selectedFilter) {
      users = (try? await fetchUsers(filter: selectedFilter)) ?? []
    }
  }
}
```

## Avoid

```swift
.onAppear {
  Task {
    await load()
  }
}
```

That pattern splits lifecycle ownership across two abstractions and makes cancellation behavior harder to reason about.

## Pitfalls

- Running expensive work in multiple `onChange` handlers when one state transition could coordinate it.
- Forgetting that `.task(id:)` cancels the previous task when the id changes.
- Using `onAppear` for repeatable async work that should really follow state changes.
