# SwiftUI Architecture Tradeoffs

## Architecture Decision Tree

```
- Existing TCA codebase already established? -> Keep TCA, extend existing reducer boundaries
- Small/medium standalone feature, Apple's patterns? -> @Observable + State-as-Bridge
- Familiar with MVVM from UIKit and presentation logic is local? -> MVVM with @Observable ViewModels
- Rigorous testability, large team, shared feature conventions? -> TCA (Composable Architecture)
- Complex navigation, deep linking, multi-flow shell? -> Add coordinator boundaries on top of the chosen state model
```

For property-wrapper selection, Observation defaults, and environment ownership, use `swiftui-patterns`. This reference is only for choosing a feature architecture and handling cross-cutting presentation tradeoffs.

## Readin Guidance

`Readin` already uses TCA as the app-wide default, with layered `App -> Presentation -> Domain/Data/Shared` boundaries and `Dependencies`-based composition in `AppDelegate`.

- Do not propose MVVM or plain `@Observable` for normal feature work inside this repo unless the user explicitly asks for an architectural migration.
- For new screens, prefer the existing `Feature` / `View` split and reducer scoping from the root shell.
- Treat coordinator-style navigation as an additive boundary around TCA state, not a replacement for reducer-driven presentation state.
- Keep business logic outside SwiftUI views even when the chosen architecture is not MVVM.

## State-as-Bridge Pattern (WWDC 2025)

Async creates suspension points that break animations:

```swift
// WRONG
Task { isLoading = true; await work(); isLoading = false }

// CORRECT - synchronous state changes for animation
withAnimation { isLoading = true }
Task {
    await work()
    withAnimation { isLoading = false }
}
```

## MVVM Structure

```swift
// Model - domain logic
struct Pet: Identifiable {
    let id: UUID; var name: String
    mutating func giveAward() { hasAward = true }
}

// ViewModel - presentation logic
@Observable
class PetListViewModel {
    private let petStore: PetStore
    var searchText = ""

    var filteredPets: [Pet] {
        petStore.myPets.filter { searchText.isEmpty || $0.name.contains(searchText) }
    }
}

// View - UI only
struct PetListView: View {
    @Bindable var viewModel: PetListViewModel

    var body: some View {
        List(viewModel.filteredPets) { PetRow(pet: $0) }
            .searchable(text: $viewModel.searchText)
    }
}
```

## TCA Trade-offs

| Scenario | Choice |
|----------|--------|
| Existing TCA product codebase | Stay on TCA |
| < 10 screens, isolated prototype | Apple patterns |
| Testability critical | TCA |
| Large team | TCA for consistency |
| Rapid prototyping | Apple patterns |
| Cross-feature state, dependency-driven side effects | TCA |

## Coordinator Boundaries

- Use a coordinator layer when flow ownership spans multiple screens, tabs, or deep-link entry points.
- Keep domain mutations and screen state inside the feature reducer/view model; the coordinator should choose routes, not absorb business rules.
- In a TCA codebase, prefer explicit navigation path state over ad-hoc callback chains.
- If navigation is still placeholder or not yet implemented, document it as scaffolding rather than treating it as a finished architectural pattern.

## Anti-Patterns

**Logic in view body:**
```swift
// WRONG - formatter created every render
var body: some View {
    let formatter = NumberFormatter()
    Text(formatter.string(from: price)!)
}

// CORRECT - cache in model
class ViewModel {
    private let formatter = NumberFormatter()
    func format(_ price: Decimal) -> String { ... }
}
```

**God ViewModel:**
```swift
// WRONG
class AppViewModel { var user; var settings; var posts; ... }

// CORRECT - separate concerns
class UserViewModel { }
class SettingsViewModel { }
```

**Architecture mismatch in an established codebase:**
```swift
// WRONG - introducing MVVM into one feature of an otherwise TCA-based app
struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()
}

// BETTER - preserve the established feature boundary
struct LibraryView: View {
    let store: StoreOf<LibraryFeature>
}
```

## Code Review Checklist

- [ ] View bodies contain ONLY UI code
- [ ] No formatters in view body
- [ ] Business logic testable without SwiftUI
- [ ] State changes for animations are synchronous
- [ ] Architecture choice matches feature complexity rather than habit
- [ ] Existing project architecture was preserved unless migration was intentional
