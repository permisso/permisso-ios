# Permisso iOS SDK

The Permisso iOS SDK provides a simple way to integrate the Permisso widget into your iOS application with proper link navigation handling and message communication.

## Features

- Easy integration with Permisso widget via web URLs
- Smart link navigation using SFSafariViewController or external Safari
- PostMessage API communication between widget and native app
- Configurable link handling modes
- Swift Package Manager support
- SwiftUI and UIKit compatibility

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/permisso/permisso-ios.git", from: "1.0.0")
]
```

Or add it through Xcode:

1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/permisso/permisso-ios.git`
3. Select the version and add to your target

## Quick Start

### UIKit Integration

```swift
import UIKit
import PermissoWebView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let permissoView = PermissoWebView(frame: view.bounds)

        // Configure message handling
        permissoView.configureMessageHandler { message in
            print("Received message: \(message)")
            // Handle the message as needed
        }

        // Load the widget
        let widgetURL = URL(string: "https://prms.io/XXXXXX")!
        permissoView.load(url: widgetURL)

        view.addSubview(permissoView)
    }
}
```

### SwiftUI Integration

```swift
import SwiftUI
import PermissoWebView

struct ContentView: View {
    let widgetURL = URL(string: "https://prms.io/XXXXXX")!

    var body: some View {
        PermissoWebViewRepresentable(url: widgetURL)
            .edgesIgnoringSafeArea(.all)
    }
}

struct PermissoWebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PermissoWebView {
        let permissoView = PermissoWebView()

        // Configure message handler
        permissoView.configureMessageHandler { message in
            print("Received message: \(message)")
            // Handle the message as needed
        }

        permissoView.load(url: url)
        return permissoView
    }

    func updateUIView(_ uiView: PermissoWebView, context: Context) {}
}
```

## Configuration Options

### Link Handling Modes

The SDK provides three different ways to handle external links:

#### Custom Tab (Recommended - Default)

Opens links in SFSafariViewController for a seamless in-app experience:

```swift
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .customTab
)
```

#### External Browser

Opens links in the default Safari browser:

```swift
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .externalBrowser
)
```

#### Custom Handling

Use your own custom logic for handling links:

```swift
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .custom,
    customLinkHandler: { url in
        // Your custom link handling logic
        print("Handle URL: \(url)")
        // Example: Present custom web view, deep link handling, etc.
    }
)
```

## Advanced Usage

### Custom Message Handling

Listen to messages from the Permisso widget by configuring a message handler:

```swift
permissoView.configureMessageHandler { messageString in
    print("🔍 Example App - Intercepted message:")
    print("   Message: \(messageString)")
    print("   ---")
}
```

## Sample App

Check out the `Example` directory in this repository for a complete integration example showing:

- Basic SwiftUI integration
- Message handling
- Link navigation configuration

To run the sample app:

1. Open `Permisso.xcworkspace`
2. Select the Example scheme
3. Build and run

## API Reference

### PermissoWebView

#### Properties

- `linkBehavior: PermissoLinkBehavior` - Current link handling behavior
- `customLinkHandler: PermissoLinkHandler?` - Custom link handler callback
- `messageHandler: PermissoMessageHandler?` - Message handler callback

#### Methods

- `load(url: URL)` - Load the Permisso widget
- `configureLinkBehavior(_:customHandler:)` - Configure link handling
- `configureMessageHandler(_:)` - Configure message handling

### PermissoLinkBehavior

- `.customTab` - Open in SFSafariViewController (recommended)
- `.externalBrowser` - Open in external Safari
- `.custom` - Use custom callback

### Type Aliases

- `PermissoLinkHandler = (URL) -> Void` - Custom link handler callback
- `PermissoMessageHandler = (String) -> Void` - Message handler callback

## License

Copyright 2025 Permisso. All rights reserved.
