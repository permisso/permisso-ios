# Changelog

All notable changes to the Permisso iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-10-22

- **Static API** for the Permisso iOS SDK

## [1.0.0] - 2025-10-12

### Added

- **Initial Release** of Permisso iOS SDK
- **PermissoWebView** - Core web view component for displaying Permisso widgets
- **PostMessage API Support** - JavaScript bridge for communication between widget and native app
- **Configurable Link Handling** - Three modes for handling external links:
  - `customTab` - Open links in SFSafariViewController (recommended)
  - `externalBrowser` - Open links in external Safari browser
  - `custom` - Use custom callback for link handling
- **Message Handler Callbacks** - Allow implementers to handle widget messages with custom logic
- **Swift Package Manager Support** - Easy installation via SPM
- **SwiftUI Compatibility** - Full support for SwiftUI applications
- **UIKit Compatibility** - Traditional UIKit integration support
- **Automatic JavaScript Injection** - Built-in message event listener for seamless communication
- **Example Application** - Complete sample app demonstrating integration patterns
