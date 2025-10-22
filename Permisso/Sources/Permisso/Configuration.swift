import UIKit
import Foundation

/// Configuration object for customizing Permisso SDK behavior.
public final class Configuration {

    /// The link handling behavior when external links are clicked in the web view.
    /// Default is `.customTab` which opens links in an in-app browser.
    public var linkBehavior: PermissoLinkBehavior = .customTab

    /// Custom handler for link navigation when `linkBehavior` is set to `.custom`.
    /// This handler will be called on a background queue to avoid blocking the UI.
    public var customLinkHandler: PermissoLinkHandler?

    /// Handler for messages received from the web content via postMessage.
    /// This handler will be called on a background queue to avoid blocking the UI.
    public var messageHandler: PermissoMessageHandler?

    /// The modal presentation style for the Permisso interface.
    /// Default is `.fullScreen` for a full-screen experience.
    public var modalPresentationStyle: UIModalPresentationStyle = .fullScreen

    public init() {
    }

    /// Convenience method to configure link behavior.
    /// - Parameters:
    ///   - behavior: The desired link handling behavior
    ///   - customHandler: Optional custom handler for `.custom` behavior
    public func setLinkBehavior(_ behavior: PermissoLinkBehavior, customHandler: PermissoLinkHandler? = nil) {
        self.linkBehavior = behavior
        self.customLinkHandler = customHandler
    }
}
