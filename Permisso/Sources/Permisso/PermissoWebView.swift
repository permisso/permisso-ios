import UIKit
import WebKit
import SafariServices // Import for the in-app browser
import os.log

// Enum to define link handling behavior
public enum PermissoLinkBehavior {
    case customTab      // Open in SFSafariViewController (in-app browser)
    case externalBrowser // Open in external Safari
    case custom         // Use custom callback
}

// Callback type for custom link handling
public typealias PermissoLinkHandler = (URL) -> Void

// Callback type for message handling
public typealias PermissoMessageHandler = (String) -> Void

public class PermissoWebView: UIView {

    // The actual web view, kept private
    private var webView: WKWebView!

    // A reference to the view controller that contains this view.
    // We need this to present the in-app browser.
    // It's weak to prevent retain cycles.
    public weak var parentViewController: UIViewController?

    // Link handling configuration
    public var linkBehavior: PermissoLinkBehavior = .customTab
    public var customLinkHandler: PermissoLinkHandler?

    // Message handling configuration
    public var messageHandler: PermissoMessageHandler?

    // Standard initializers
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    // Convenience initializer with link behavior configuration
    public init(frame: CGRect, linkBehavior: PermissoLinkBehavior, customLinkHandler: PermissoLinkHandler? = nil) {
        super.init(frame: frame)
        self.linkBehavior = linkBehavior
        self.customLinkHandler = customLinkHandler
        setupWebView()
    }

    // Convenience initializer with message handler configuration
    public init(frame: CGRect, messageHandler: PermissoMessageHandler? = nil) {
        super.init(frame: frame)
        self.messageHandler = messageHandler
        setupWebView()
    }

    // Full configuration initializer
    public init(frame: CGRect, linkBehavior: PermissoLinkBehavior, customLinkHandler: PermissoLinkHandler? = nil, messageHandler: PermissoMessageHandler? = nil) {
        super.init(frame: frame)
        self.linkBehavior = linkBehavior
        self.customLinkHandler = customLinkHandler
        self.messageHandler = messageHandler
        setupWebView()
    }

    // Configuration logic
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        // Important: This allows JavaScript to open windows
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Add message handler to intercept postMessage events
        let contentController = configuration.userContentController
        contentController.add(self, name: "iosBridge")

        // Inject JavaScript to listen for postMessage events
        let postMessageScript = """
        window.addEventListener('message', function(e) {
          try {
            var data = e.data;
            if (typeof data === 'string') {
              try { data = JSON.parse(data); } catch(_) {}
            }

            if (window.webkit?.messageHandlers?.iosBridge) {
              window.webkit.messageHandlers.iosBridge.postMessage(JSON.stringify(data));
            }
          } catch (err) {
            console.log("iosBridge error:", err);
          }
        });
        """

        let userScript = WKUserScript(source: postMessageScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(userScript)

        webView = WKWebView(frame: self.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Set the delegate that handles UI events like opening new tabs
        webView.uiDelegate = self

        self.addSubview(webView)
    }

    // Public method for the customer to load the widget URL
    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // Public method to configure link handling behavior
    public func configureLinkBehavior(_ behavior: PermissoLinkBehavior, customHandler: PermissoLinkHandler? = nil) {
        self.linkBehavior = behavior
        self.customLinkHandler = customHandler
    }

    // Public method to configure message handling
    public func configureMessageHandler(_ handler: PermissoMessageHandler?) {
        self.messageHandler = handler
    }

    // Cleanup when the view is deallocated
    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "iosBridge")
    }
}

// Extension to handle new window requests
extension PermissoWebView: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard let url = navigationAction.request.url else { return nil }

        handleLinkNavigation(url: url)
        return nil
    }

    // Handle link navigation based on configured behavior
    private func handleLinkNavigation(url: URL) {
        switch linkBehavior {
        case .customTab:
            // Open in SFSafariViewController (in-app browser)
            if let parentVC = findParentViewController() {
                let safariVC = SFSafariViewController(url: url)
                parentVC.present(safariVC, animated: true)
            } else {
                // Fallback to external browser if no parent VC found
                UIApplication.shared.open(url)
            }

        case .externalBrowser:
            // Open in external Safari
            UIApplication.shared.open(url)

        case .custom:
            // Use custom handler if provided, otherwise fallback to custom tab
            if let customHandler = customLinkHandler {
                customHandler(url)
            } else {
                // Fallback to custom tab if no custom handler is provided
                if let parentVC = findParentViewController() {
                    let safariVC = SFSafariViewController(url: url)
                    parentVC.present(safariVC, animated: true)
                } else {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // Helper function to traverse the UI hierarchy and find the containing UIViewController
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let vc = nextResponder as? UIViewController {
                return vc
            }
            responder = nextResponder
        }
        return nil
    }
}

// Extension to handle intercepted postMessage events
extension PermissoWebView: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "iosBridge" else { return }

        if let messageString = message.body as? String {
            // Call the custom message handler if provided
            if let handler = messageHandler {
                handler(messageString)
            }
        }
    }
}
