# Accessibility

## Intent

Use these patterns when a SwiftUI screen has interactive content, dynamic text, or custom actions that must remain accessible.

## Core rules

- Mark decorative content as hidden from accessibility when it should not be announced.
- Combine related child views into a single accessible element when that matches how users understand the row or card.
- Use Dynamic Type friendly layout and `@ScaledMetric` for fixed sizes that should scale with text size.
- Add custom accessibility actions when gestures or hidden affordances would otherwise be inaccessible.

## Example: combined row

```swift
struct ArticleRow: View {
  let article: Article

  var body: some View {
    HStack {
      AsyncImage(url: article.imageURL) { image in
        image.resizable()
      } placeholder: {
        ProgressView()
      }
      .frame(width: 80, height: 80)
      .accessibilityHidden(true)

      VStack(alignment: .leading) {
        Text(article.title)
          .font(.headline)
        Text(article.author)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(article.title), \(article.author)")
    .accessibilityHint("Opens the article")
  }
}
```

## Example: Dynamic Type aware media

```swift
struct ArticleContent: View {
  let article: Article
  @ScaledMetric private var imageHeight: CGFloat = 200

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        AsyncImage(url: article.imageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          ProgressView()
        }
        .frame(height: imageHeight)
        .clipped()

        Text(article.title)
          .font(.title)
        Text(article.content)
          .font(.body)
      }
    }
  }
}
```

## Pitfalls

- Relying only on color, blur, or motion to communicate state.
- Leaving tappable rows as multiple disjoint accessibility elements without intent.
- Hard-coding fixed sizes that break with large content sizes.
