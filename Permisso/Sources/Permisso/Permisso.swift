import UIKit
import Foundation

/// The main Permisso SDK class providing a static API for easy integration.
/// This is the recommended way to use the Permisso SDK for most use cases.
///
/// **Basic Usage:**
/// ```swift
/// Permisso.shared.configure { config in
///     config.linkBehavior = .externalBrowser
/// }
/// Permisso.shared.present(from: self, url: url)
/// ```
public final class Permisso {

    /// The shared singleton instance of Permisso.
    public static let shared = Permisso()

    /// The current configuration for the SDK.
    private var configuration = Configuration()

    /// Prevent external instantiation - use the shared instance
    private init() {
    }

    /// Configure the Permisso SDK with custom settings.
    /// This method can be called multiple times to update the configuration.
    ///
    /// - Parameter configurationBlock: A closure that receives the configuration object to modify
    ///
    /// **Example:**
    /// ```swift
    /// Permisso.shared.configure { config in
    ///     config.linkBehavior = .externalBrowser
    ///     config.messageHandler = { message in
    ///         print("Received message: \(message)")
    ///     }
    /// }
    /// ```
    public func configure(_ configurationBlock: (Configuration) -> Void) {
        configurationBlock(configuration)
    }

    /// Present the Permisso web interface from the given view controller.
    /// The web interface will be presented modally with a navigation bar and close button.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - url: The Permisso URL to load
    ///   - animated: Whether to animate the presentation (default: true)
    ///   - completion: Optional completion handler called after presentation
    ///
    /// **Example:**
    /// ```swift
    /// let url = URL(string: "https://prms.io/s/YOUR_ID")!
    /// Permisso.shared.present(from: self, url: url)
    /// ```
    public func present(
        from viewController: UIViewController,
        url: URL,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        // Create the internal view controller with current configuration
        let permissoController = PermissoWebViewController(
            configuration: configuration,
            url: url
        )

        // Apply the configured modal presentation style
        permissoController.modalPresentationStyle = configuration.modalPresentationStyle

        // Present modally
        viewController.present(permissoController, animated: animated, completion: completion)
    }
}
