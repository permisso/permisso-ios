import SwiftUI
import WebKit
import Permisso
import os.log

/// SwiftUI wrapper for the advanced PermissoWebView API.
///
/// ⚠️ **This is for demonstration of the advanced API only.**
/// **Most apps should use the static API instead:**
/// ```swift
/// Permisso.shared.present(from: self, url: url)
/// ```
struct PermissoWebViewRepresentable: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> PermissoWebView {
        let permissoView = PermissoWebView()

        // Configure the message handler to demonstrate advanced API usage
        permissoView.configureMessageHandler { messageString in
            // Log the intercepted message
            let logger = Logger(subsystem: "io.permisso.Example", category: "AdvancedAPI")

            logger.info("📨 Advanced API - Intercepted message: \(messageString)")

            // Also log to console for debugging
            print("🔍 Advanced API Example - Intercepted message:")
            print("   Message: \(messageString)")
            print("   API: PermissoWebView (Advanced)")
            print("   ---")
        }

        // Configure link behavior for the advanced API
        permissoView.configureLinkBehavior(.customTab)

        // Set parent view controller (required for the advanced API)
        permissoView.parentViewController = context.coordinator.findParentViewController(for: permissoView)

        permissoView.load(url: url)
        return permissoView
    }

    func updateUIView(_ uiView: PermissoWebView, context: Context) {
        // Update parent view controller reference if needed
        if uiView.parentViewController == nil {
            uiView.parentViewController = context.coordinator.findParentViewController(for: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        func findParentViewController(for view: UIView) -> UIViewController? {
            var responder: UIResponder? = view
            while let nextResponder = responder?.next {
                if let vc = nextResponder as? UIViewController {
                    return vc
                }
                responder = nextResponder
            }
            return nil
        }
    }
}
