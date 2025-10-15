import SwiftUI
import PermissoWebView
import os.log

@main
struct ExampleApp: App {
    
    init() {
        // Conditionally preload WebKit processes during app initialization
        // Skip preloading if we're in a problematic environment
        #if !targetEnvironment(macCatalyst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Try preloading with fallback for sandbox issues
            PermissoWebView.preloadWebKitProcesses()
        }
        #else
        os_log("Skipping WebKit preload on macCatalyst", log: OSLog.default, type: .info)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
