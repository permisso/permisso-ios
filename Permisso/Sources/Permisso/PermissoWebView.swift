import UIKit
import WebKit
import SafariServices // Import for the in-app browser
import os.log

// Shared process pool to improve WebKit performance and reduce startup time
extension WKProcessPool {
    static let shared: WKProcessPool = {
        let pool = WKProcessPool()
        return pool
    }()
}

// Shared website data store to reduce process overhead
extension WKWebsiteDataStore {
    static let optimized: WKWebsiteDataStore = {
        let store = WKWebsiteDataStore.default()
        return store
    }()
}

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

    // Configuration logic with aggressive performance optimizations
    private func setupWebView() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setupWebView()
            }
            return
        }
        
        let configuration = WKWebViewConfiguration()
        
        // CRITICAL: Use shared process pool to prevent multiple WebKit process launches
        configuration.processPool = WKProcessPool.shared
        configuration.websiteDataStore = WKWebsiteDataStore.optimized
        
        // Aggressive simulator optimizations to prevent GPU/WebContent process delays
        #if targetEnvironment(simulator)
        // Safely disable GPU acceleration and hardware features that cause delays
        if configuration.preferences.responds(to: Selector(("setValue:forKey:"))) {
            configuration.preferences.setValue(false, forKey: "acceleratedDrawingEnabled")
            configuration.preferences.setValue(false, forKey: "canvasUsesAcceleratedDrawing")
            configuration.preferences.setValue(false, forKey: "webGLEnabled")
            configuration.preferences.setValue(false, forKey: "acceleratedCompositingEnabled")
        }
        
        // Reduce memory pressure that can slow process launching
        if configuration.responds(to: Selector(("setValue:forKey:"))) {
            configuration.setValue(false, forKey: "allowsInlineMediaPlayback")
            configuration.setValue([], forKey: "mediaTypesRequiringUserActionForPlayback")
        }
        #else
        // Enable optimizations for real devices
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        #endif
        
        // Essential WebKit optimizations
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences.javaScriptEnabled = true
        configuration.suppressesIncrementalRendering = true // Faster initial render
        
        // Minimize user content controller overhead
        let contentController = configuration.userContentController
        contentController.add(self, name: "iosBridge")

        // Optimized JavaScript injection - minimal and fast
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

        let userScript = WKUserScript(source: postMessageScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        // Create WebView with error handling
        do {
            webView = WKWebView(frame: self.bounds, configuration: configuration)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Performance optimizations for simulator
            #if targetEnvironment(simulator)
            webView.scrollView.layer.shouldRasterize = false
            webView.layer.shouldRasterize = false
            webView.scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
            #endif
            
            // Optimize scrolling performance
            webView.scrollView.bounces = false
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never

            // Set delegates for comprehensive handling
            webView.uiDelegate = self
            webView.navigationDelegate = self

            self.addSubview(webView)
            
            os_log("WebView created successfully", log: OSLog.default, type: .info)
            
        } catch {
            os_log("Failed to create WebView: %@", log: OSLog.default, type: .error, error.localizedDescription)
            // Create a fallback view or handle the error appropriately
            createFallbackView()
        }
    }
    
    // Fallback method when WebView creation fails
    private func createFallbackView() {
        let fallbackLabel = UILabel(frame: self.bounds)
        fallbackLabel.text = "WebView initialization failed. Please restart the app."
        fallbackLabel.textAlignment = .center
        fallbackLabel.numberOfLines = 0
        fallbackLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fallbackLabel.backgroundColor = UIColor.white
        self.addSubview(fallbackLabel)
    }

    // Optimized method for loading URLs with enhanced error handling
    public func load(url: URL) {
        // Validate URL before loading
        guard url.scheme == "http" || url.scheme == "https" else {
            os_log("Invalid URL scheme for WebView: %@", log: OSLog.default, type: .error, url.absoluteString)
            return
        }
        
        var request = URLRequest(url: url)
        
        // Network optimizations to reduce load time
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15.0 // Reduced timeout for faster failure detection
        
        // Optimized headers for better performance
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("1", forHTTPHeaderField: "DNT") // Do Not Track for privacy
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        // Load with enhanced error handling
        DispatchQueue.main.async { [weak self] in
            self?.webView.load(request)
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
    
    // Method to handle WebKit process failures and attempt recovery
    public func handleWebKitFailure() {
        os_log("Attempting WebKit recovery due to process failure", log: OSLog.default, type: .info)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove current WebView
            self.webView?.removeFromSuperview()
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "iosBridge")
            
            // Force cleanup
            self.webView = nil
            
            // Wait briefly for cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Recreate WebView with fresh configuration
                self.setupWebView()
            }
        }
    }
    
    // Method to preload WebKit processes to reduce initial startup time
    public static func preloadWebKitProcesses() {
        // Only preload on main thread to avoid WebKit initialization issues
        DispatchQueue.main.async {
            #if targetEnvironment(simulator)
            os_log("Attempting WebKit preload in simulator environment", log: OSLog.default, type: .info)
            #endif
            
            do {
                // Create a minimal WebView configuration to initialize WebKit processes
                let config = WKWebViewConfiguration()
                config.processPool = WKProcessPool.shared
                config.websiteDataStore = WKWebsiteDataStore.optimized
                
                #if targetEnvironment(simulator)
                // Disable GPU-intensive features for simulator with error handling
                if config.preferences.responds(to: Selector(("setValue:forKey:"))) {
                    config.preferences.setValue(false, forKey: "acceleratedDrawingEnabled")
                    config.preferences.setValue(false, forKey: "webGLEnabled")
                }
                
                // Additional simulator-specific sandbox workarounds
                config.suppressesIncrementalRendering = true
                config.preferences.javaScriptEnabled = true
                #endif
                
                // Create temporary WebView to warm up processes with minimal size
                let tempWebView = WKWebView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1), configuration: config)
                
                // Load minimal HTML to initialize processes
                tempWebView.loadHTMLString("<html><head><title>Init</title></head><body></body></html>", baseURL: nil)
                
                // Clean up after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    tempWebView.removeFromSuperview()
                    os_log("WebKit processes preloaded successfully", log: OSLog.default, type: .info)
                }
                
            } catch {
                os_log("WebKit preloading failed - possible sandbox extension issue: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
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

// Extension to handle navigation and WebKit process issues
extension PermissoWebView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        os_log("WebView started loading", log: OSLog.default, type: .info)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        os_log("WebView committed navigation", log: OSLog.default, type: .info)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log("WebView finished loading", log: OSLog.default, type: .info)
        
        // Inject performance optimizations after page load for simulator
        #if targetEnvironment(simulator)
        let performanceScript = """
        // Disable animations and transitions that can cause GPU process issues
        (function() {
            var style = document.createElement('style');
            style.innerHTML = `
                *, *::before, *::after {
                    animation-duration: 0s !important;
                    animation-delay: 0s !important;
                    transition-duration: 0s !important;
                    transition-delay: 0s !important;
                }
            `;
            document.head.appendChild(style);
            
            // Disable WebGL and GPU-intensive features
            if (window.WebGLRenderingContext) {
                window.WebGLRenderingContext = undefined;
            }
            if (window.WebGL2RenderingContext) {
                window.WebGL2RenderingContext = undefined;
            }
        })();
        """
        
        webView.evaluateJavaScript(performanceScript) { _, error in
            if let error = error {
                os_log("Performance script injection failed: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
        #endif
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log("WebView navigation failed: %@", log: OSLog.default, type: .error, error.localizedDescription)
        handleNavigationError(error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        os_log("WebView provisional navigation failed: %@", log: OSLog.default, type: .error, error.localizedDescription)
        handleNavigationError(error)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Handle navigation policies to prevent resource-heavy requests in simulator
        #if targetEnvironment(simulator)
        if let url = navigationAction.request.url {
            // Block resource-intensive content in simulator
            let blockedExtensions = ["mp4", "mov", "avi", "webm", "pdf"]
            if blockedExtensions.contains(url.pathExtension.lowercased()) {
                os_log("Blocking resource-intensive content in simulator: %@", log: OSLog.default, type: .info, url.absoluteString)
                decisionHandler(.cancel)
                return
            }
        }
        #endif
        
        decisionHandler(.allow)
    }
    
    private func handleNavigationError(_ error: Error) {
        // Handle specific WebKit errors related to process failures
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorTimedOut:
            os_log("Navigation timeout - possibly due to slow WebKit process startup", log: OSLog.default, type: .error)
        case NSURLErrorCannotConnectToHost:
            os_log("Cannot connect to host - check network connectivity", log: OSLog.default, type: .error)
        default:
            os_log("Navigation error: %@ (Code: %d)", log: OSLog.default, type: .error, nsError.localizedDescription, nsError.code)
        }
    }
}
