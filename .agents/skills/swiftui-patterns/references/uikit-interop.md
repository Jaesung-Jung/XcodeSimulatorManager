# UIKit interoperability

## Intent

Use these patterns when SwiftUI must wrap UIKit views or controllers such as `WKWebView`, `PHPickerViewController`, or custom UIKit components.

## Core rules

- Keep UIKit wrappers thin and move business logic back into SwiftUI models or services.
- Use a coordinator only for delegate bridging and imperative callbacks.
- Clean up delegate or callback cycles to avoid leaks.
- Prefer SwiftUI-native APIs first; only wrap UIKit when the platform API still requires it.

## Example: `UIViewRepresentable`

```swift
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  let url: URL
  @Binding var isLoading: Bool

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    webView.load(URLRequest(url: url))
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(isLoading: $isLoading)
  }

  final class Coordinator: NSObject, WKNavigationDelegate {
    @Binding var isLoading: Bool

    init(isLoading: Binding<Bool>) {
      _isLoading = isLoading
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
      isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
      isLoading = false
    }
  }
}
```

## Example: `UIViewControllerRepresentable`

```swift
import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 1

    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(image: $image, dismiss: dismiss)
  }
}
```

## Pitfalls

- Recreating expensive UIKit views unnecessarily in `updateUIView`.
- Putting long-lived app state into the coordinator.
- Forgetting to break delegate or closure cycles when the wrapped view outlives the SwiftUI container.
