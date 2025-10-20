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

        // Performance optimizations
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Add message handler to intercept postMessage events
        let contentController = configuration.userContentController

        // This allows us to listen for messages from the web content
        contentController.add(self, name: "iosBridge")

        // Inject JavaScript to listen for postMessage events
        let postMessageScriptSource = """
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
        let userScript = WKUserScript(
            source: postMessageScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(userScript)

        // Disable zoom through injected JavaScript
        let viewportScriptSource = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let viewportScript = WKUserScript(
            source: viewportScriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(viewportScript)

        webView = WKWebView(frame: self.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Set the delegate that handles UI events like opening new tabs
        webView.uiDelegate = self

        // Disable scroll
        webView.scrollView.bounces = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        self.addSubview(webView)
    }

    // Public method for the customer to load the widget URL
    public func load(url: URL) {
        // Ensure web view loading happens on the main thread, but don't block if called from background
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
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
        cleanup()
    }

    // Explicit cleanup method
    private func cleanup() {
        // Remove script message handler to prevent memory leaks
        if let webView = webView {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "iosBridge")
            webView.uiDelegate = nil
        }

        // Clear references
        webView = nil
        customLinkHandler = nil
        messageHandler = nil
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
        // Dispatch UI operations to main thread to avoid blocking
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch self.linkBehavior {
            case .customTab:
                // Open in SFSafariViewController (in-app browser)
                if let parentVC = self.findParentViewController() {
                    let safariVC = SFSafariViewController(url: url)
                    parentVC.present(safariVC, animated: true)
                } else {
                    // Fallback to external browser if no parent VC found
                    // Dispatch URL opening to background thread to avoid blocking UI
                    DispatchQueue.global(qos: .userInitiated).async {
                        UIApplication.shared.open(url)
                    }
                }

            case .externalBrowser:
                // Open in external Safari - dispatch to background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    UIApplication.shared.open(url)
                }

            case .custom:
                // Use custom handler if provided, otherwise fallback to custom tab
                if let customHandler = self.customLinkHandler {
                    // Custom handlers might perform network operations, so dispatch to background
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        // Ensure self is still alive when executing the handler
                        guard self != nil else { return }
                        customHandler(url)
                    }
                } else {
                    // Fallback to custom tab if no custom handler is provided
                    if let parentVC = self.findParentViewController() {
                        let safariVC = SFSafariViewController(url: url)
                        parentVC.present(safariVC, animated: true)
                    } else {
                        DispatchQueue.global(qos: .userInitiated).async {
                            UIApplication.shared.open(url)
                        }
                    }
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
            // Dispatch message handling to background thread to avoid blocking UI
            if let handler = messageHandler {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    // Ensure self is still alive when executing the handler
                    guard self != nil else { return }
                    handler(messageString)
                }
            }
        }
    }
}
