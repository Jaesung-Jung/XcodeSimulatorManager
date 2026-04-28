# View composition

## Intent

Use composition to keep SwiftUI screens readable: small subviews, narrow inputs, and reusable modifiers instead of one large `body`.

## Core rules

- Extract repeated layout or styling into dedicated subviews before reaching for `AnyView`.
- Keep helper views close to the parent when they are feature-specific.
- Use local `@ViewBuilder` helpers for small conditional branches, not for whole screens with hidden side effects.
- Prefer small custom modifiers for repeated styling or behavior.

## Example: local `@ViewBuilder`

```swift
struct ArticleCard: View {
  let article: Article
  let style: CardStyle

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      content
      footer
    }
    .padding()
    .background(cardBackground)
  }

  @ViewBuilder
  private var header: some View {
    if let imageURL = article.imageURL {
      AsyncImage(url: imageURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        ProgressView()
      }
      .frame(height: 200)
      .clipped()
    }
  }

  @ViewBuilder
  private var content: some View {
    Text(article.title)
      .font(.headline)

    if style == .detailed {
      Text(article.summary)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .lineLimit(3)
    }
  }

  private var footer: some View {
    HStack {
      Text(article.author)
      Spacer()
      Text(article.publishedAt, style: .relative)
    }
    .font(.caption)
    .foregroundColor(.secondary)
  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(.background)
      .shadow(radius: 2)
  }
}
```

## Example: custom modifier

```swift
struct CardChrome: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(.background, in: RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
  }
}

extension View {
  func cardChrome() -> some View {
    modifier(CardChrome())
  }
}
```

## Pitfalls

- Splitting a view into so many fragments that data flow becomes harder to follow.
- Hiding mutations or async side effects inside computed `some View` helpers.
- Using `AnyView` to erase type issues that should be solved through better structure.
