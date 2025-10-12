import UIKit
import WebKit
import SafariServices // Import for the in-app browser

public class PermissoWebView: UIView {

    // The actual web view, kept private
    private var webView: WKWebView!

    // A reference to the view controller that contains this view.
    // We need this to present the in-app browser.
    // It's weak to prevent retain cycles.
    public weak var parentViewController: UIViewController?

    // Standard initializers
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    // Configuration logic
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        // Important: This allows JavaScript to open windows
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

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
}

// Extension to handle new window requests
extension PermissoWebView: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard let url = navigationAction.request.url else { return nil }
        
        // Smartly find the parent view controller when it's needed!
        if let parentVC = findParentViewController() {
            let safariVC = SFSafariViewController(url: url)
            parentVC.present(safariVC, animated: true)
        } else {
            // Fallback for edge cases where the view controller can't be found
            UIApplication.shared.open(url)
        }

        return nil
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
