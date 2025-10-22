# Permisso iOS SDK

The Permisso iOS SDK provides a simple way to integrate the Permisso widget into your iOS application with proper link navigation handling and message communication.

## Features

- **Static API**: Simple one-line integration for most use cases
- **Custom Web Views**: Advanced control for custom layouts and interactions
- Smart link navigation using SFSafariViewController or external Safari
- PostMessage API communication between widget and native app
- Configurable link handling modes
- Swift Package Manager support
- SwiftUI and UIKit compatibility

## Integration Approaches

### Static API (Recommended)

**Use when:**

- You want to present Permisso as a modal overlay
- You need quick and simple integration
- You don't need custom layouts or embedding
- You want automatic handling of navigation and close actions

**Benefits:**

- One-line presentation: `Permisso.shared.present(from: self, url: url)`
- Automatic navigation bar with close button
- Global configuration that persists across presentations
- Handles view controller lifecycle automatically

### Custom Web View Integration

**Use when:**

- You need to embed Permisso within existing UI layouts
- You want custom navigation controls
- You need fine-grained control over the web view lifecycle
- You're building custom container views

**Benefits:**

- Complete control over layout and positioning
- Custom navigation and UI integration
- Direct access to web view delegate methods
- Flexible embedding within existing view hierarchies

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/permisso/permisso-ios.git", from: "1.0.1")
]
```

Or add it through Xcode:

1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/permisso/permisso-ios.git`
3. Select the version and add to your target

## Minimal Example

Get started with just a few lines of code:

```swift
import Permisso

// Present Permisso with one line of code
let url = URL(string: "https://prms.io/s/YOUR_ID")!
Permisso.shared.present(from: viewController, url: url)
```

That's it! Permisso will be presented modally with automatic handling of links and navigation.

## Quick Start

### Using the Static API (Recommended)

The easiest way to integrate Permisso is using the static API, which handles presentation and navigation automatically. Here's the minimal integration:

```swift
import UIKit
import Permisso

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure Permisso (optional - has sensible defaults)
        Permisso.shared.configure { config in
            config.linkBehavior = .customTab  // Open links in SFSafariViewController
            config.messageHandler = { message in
                print("Received message: \(message)")
                // Handle messages from Permisso widget
            }
        }
    }

    @IBAction func presentPermisso(_ sender: UIButton) {
        let widgetURL = URL(string: "https://prms.io/s/XXXXXX")!

        // Present Permisso modally with a single method call
        Permisso.shared.present(from: self, url: widgetURL) {
            print("Permisso presentation completed")
        }
    }
}
```

### SwiftUI Integration

```swift
import SwiftUI
import Permisso

struct ContentView: View {
    let widgetURL = URL(string: "https://prms.io/XXXXXX")!

    var body: some View {
        VStack {
            Text("My App")
                .font(.largeTitle)

            Button("Open Permisso") {
                presentPermisso()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func presentPermisso() {
        // Configure Permisso
        Permisso.shared.configure { config in
            config.linkBehavior = .customTab
            config.messageHandler = { message in
                print("Received message: \(message)")
            }
        }

        // Find the root view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        // Present Permisso
        Permisso.shared.present(from: topViewController, url: widgetURL)
    }
}
```

## Configuration Options

### Static API Configuration

Configure the global Permisso instance with your preferred settings:

```swift
Permisso.shared.configure { config in
    // Link handling behavior
    config.linkBehavior = .customTab  // .customTab, .externalBrowser, or .custom

    // Message handling
    config.messageHandler = { message in
        print("Received message: \(message)")
        // Process messages from Permisso widget
    }

    // Modal presentation style
    config.modalPresentationStyle = .fullScreen  // or .pageSheet, .formSheet, etc.

    // Custom link handler (when linkBehavior is .custom)
    config.customLinkHandler = { url in
        print("Custom handling for URL: \(url)")
        // Your custom link handling logic
    }
}
```

### Link Handling Modes

The SDK provides three different ways to handle external links:

#### Custom Tab (Recommended - Default)

Opens links in SFSafariViewController for a seamless in-app experience:

```swift
// Static API
Permisso.shared.configure { config in
    config.linkBehavior = .customTab
}

// Direct PermissoWebView (Advanced)
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .customTab
)
```

#### External Browser

Opens links in the default Safari browser:

```swift
// Static API
Permisso.shared.configure { config in
    config.linkBehavior = .externalBrowser
}

// Direct PermissoWebView (Advanced)
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .externalBrowser
)
```

#### Custom Handling

Use your own custom logic for handling links:

```swift
// Static API
Permisso.shared.configure { config in
    config.linkBehavior = .custom
    config.customLinkHandler = { url in
        // Your custom link handling logic
        print("Handle URL: \(url)")
        // Example: Present custom web view, deep link handling, etc.
    }
}

// Direct PermissoWebView (Advanced)
let permissoView = PermissoWebView(
    frame: bounds,
    linkBehavior: .custom,
    customLinkHandler: { url in
        // Your custom link handling logic
        print("Handle URL: \(url)")
    }
)
```

## Advanced Usage

### Static API Advanced Features

#### Multiple Configuration Updates

You can call `configure` multiple times to update settings:

```swift
// Initial configuration
Permisso.shared.configure { config in
    config.linkBehavior = .customTab
}

// Later, update just the message handler
Permisso.shared.configure { config in
    config.messageHandler = { message in
        // Handle messages based on current app state
        if userIsLoggedIn {
            processUserMessage(message)
        }
    }
}
```

#### Presentation Completion Handling

```swift
Permisso.shared.present(from: viewController, url: url) {
    // Called after the Permisso interface is presented
    print("Permisso is now visible")

    // Update UI, track analytics, etc.
    Analytics.track("permisso_presented")
}
```

#### Custom Modal Presentation Styles

```swift
Permisso.shared.configure { config in
    config.modalPresentationStyle = .pageSheet  // iOS 13+ style sheet
    // Or .formSheet, .overFullScreen, etc.
}
```

### Custom Web View Integration (Advanced)

For cases where you need direct control over the web view layout, use `PermissoWebView` directly:

#### UIKit Custom Integration

```swift
import UIKit
import Permisso

class CustomPermissoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let permissoView = PermissoWebView(frame: view.bounds)

        // Configure message handling
        permissoView.configureMessageHandler { message in
            print("🔍 Custom Integration - Received message:")
            print("   Message: \(message)")
            print("   ---")
        }

        // Configure link handling
        permissoView.configureLinkBehavior(.customTab)

        // Load the widget
        let widgetURL = URL(string: "https://prms.io/XXXXXX")!
        permissoView.load(url: widgetURL)

        view.addSubview(permissoView)

        // Add constraints for custom layouts
        permissoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            permissoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            permissoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            permissoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            permissoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
```

#### SwiftUI Custom Integration

```swift
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

struct ContentView: View {
    let widgetURL = URL(string: "https://prms.io/XXXXXX")!

    var body: some View {
        PermissoWebViewRepresentable(url: widgetURL)
            .edgesIgnoringSafeArea(.all)
    }
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

### Permisso (Static API)

The main class providing a simple, static API for Permisso integration.

#### Properties

- `static let shared: Permisso` - The singleton instance

#### Methods

- `configure(_ configurationBlock: (Configuration) -> Void)` - Configure SDK settings
- `present(from:url:animated:completion:)` - Present Permisso modally

**Example:**

```swift
Permisso.shared.configure { config in
    config.linkBehavior = .customTab
}

Permisso.shared.present(from: viewController, url: url) {
    print("Presentation completed")
}
```

### Configuration

Configuration object for customizing Permisso SDK behavior.

#### Configuration Properties

- `linkBehavior: PermissoLinkBehavior` - Link handling behavior (default: `.customTab`)
- `customLinkHandler: PermissoLinkHandler?` - Custom link handler for `.custom` behavior
- `messageHandler: PermissoMessageHandler?` - Handler for messages from web content
- `modalPresentationStyle: UIModalPresentationStyle` - Modal presentation style (default: `.fullScreen`)

#### Configuration Methods

- `setLinkBehavior(_:customHandler:)` - Convenience method to configure link behavior

### PermissoWebView (Advanced)

Direct web view component for custom integrations.

#### PermissoWebView Properties

- `linkBehavior: PermissoLinkBehavior` - Current link handling behavior
- `customLinkHandler: PermissoLinkHandler?` - Custom link handler callback
- `messageHandler: PermissoMessageHandler?` - Message handler callback

#### PermissoWebView Methods

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
