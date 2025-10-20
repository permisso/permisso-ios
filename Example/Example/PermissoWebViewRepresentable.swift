import SwiftUI
import WebKit
import Permisso
import os.log

struct PermissoWebViewRepresentable: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> PermissoWebView {
        let permissoView = PermissoWebView()

        // Configure the message handler
        permissoView.configureMessageHandler { messageString in
            // Log the intercepted message
            let logger = Logger(subsystem: "io.permisso.Example", category: "MessageEvent")

            logger.info("📨 Intercepted message: \(messageString)")

            // Also log to console for debugging
            print("🔍 Example App - Intercepted message:")
            print("   Message: \(messageString)")
            print("   ---")
        }

        permissoView.load(url: url)
        return permissoView
    }

    func updateUIView(_ uiView: PermissoWebView, context: Context) {}

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
