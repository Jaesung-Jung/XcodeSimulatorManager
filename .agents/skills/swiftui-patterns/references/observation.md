# Observation models

## Intent

Use this reference when a SwiftUI feature needs reference state on iOS 17+ and the Observation framework is available.

## Core rules

- Prefer `@Observable` for new reference models instead of `ObservableObject`.
- Keep UI-facing observable models `@MainActor` when they mutate state that drives rendering.
- Root views own feature-scoped observable models with `@State`.
- Child views receive observable models as stored properties and add `@Bindable` only when they need two-way bindings.
- Do not mix `@Observable` with `@Published`, `@StateObject`, or `@EnvironmentObject`.

## Example: feature-scoped model

```swift
import Observation
import SwiftUI

@MainActor
@Observable
final class ArticleListModel {
  var articles: [Article] = []
  var isLoading = false
  var errorMessage: String?

  private let articleClient: ArticleClient

  init(articleClient: ArticleClient) {
    self.articleClient = articleClient
  }

  func load() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      articles = try await articleClient.fetchArticles()
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

struct ArticleListView: View {
  @State private var model: ArticleListModel

  init(articleClient: ArticleClient) {
    _model = State(wrappedValue: ArticleListModel(articleClient: articleClient))
  }

  var body: some View {
    List(model.articles) { article in
      Text(article.title)
    }
    .overlay {
      if model.isLoading {
        ProgressView()
      }
    }
    .task {
      await model.load()
    }
  }
}
```

## Example: child mutation with `@Bindable`

```swift
struct ArticleEditorView: View {
  @Bindable var model: ArticleDraftModel

  var body: some View {
    Form {
      TextField("Title", text: $model.title)
      TextField("Summary", text: $model.summary, axis: .vertical)
    }
  }
}
```

Only use `@Bindable` when the child needs bindings. Read-only children can store the model without it.

## When not to use a separate model

- A few local toggles, selections, or presentation flags still belong in plain `@State`.
- If the type only formats data and has no lifecycle or mutation logic, prefer a helper or derived value.
- In TCA features, keep domain state in the reducer and use SwiftUI observation only at the view layer.

## Pitfalls

- Creating the model inline in `body`, which reinitializes it on every render.
- Wrapping an `@Observable` type in `@StateObject` or `@ObservedObject`.
- Adding `@Bindable` everywhere, which broadens mutation scope without benefit.
