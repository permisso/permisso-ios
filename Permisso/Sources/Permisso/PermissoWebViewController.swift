import UIKit
import SafariServices

/// Internal view controller that wraps PermissoWebView for presentation.
/// This is used internally by the static API and should not be used directly.
internal final class PermissoWebViewController: UIViewController {

    private let permissoWebView: PermissoWebView
    private let configuration: Configuration
    private let url: URL

    /// Navigation bar for presenting close button and title
    private let navigationBar = UINavigationBar()
    private let customNavigationItem = UINavigationItem()

    /// Initialize with configuration and URL
    /// - Parameters:
    ///   - configuration: The SDK configuration
    ///   - url: The URL to load in the web view
    init(configuration: Configuration, url: URL) {
        self.configuration = configuration
        self.url = url
        self.permissoWebView = PermissoWebView()
        super.init(nibName: nil, bundle: nil)

        setupWebView()
        setupNavigationBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground
        setupLayout()

        // Load the URL
        permissoWebView.load(url: url)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Ensure we're presented modally with proper style
        if let presentationController = presentationController {
            presentationController.delegate = self
        }
    }

    private func setupWebView() {
        // Apply configuration to the web view
        permissoWebView.linkBehavior = configuration.linkBehavior
        permissoWebView.customLinkHandler = configuration.customLinkHandler
        permissoWebView.messageHandler = configuration.messageHandler
        permissoWebView.parentViewController = self

        // Apply scroll and zoom settings
        permissoWebView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupNavigationBar() {
        // Setup close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        customNavigationItem.leftBarButtonItem = closeButton
        customNavigationItem.title = "Permisso"

        navigationBar.setItems([customNavigationItem], animated: false)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        // Style the navigation bar
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }

    private func setupLayout() {
        view.addSubview(navigationBar)
        view.addSubview(permissoWebView)

        NSLayoutConstraint.activate([
            // Navigation bar constraints
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Web view constraints
            permissoWebView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            permissoWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            permissoWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            permissoWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PermissoWebViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Handle any cleanup if needed when dismissed by swipe
    }
}
