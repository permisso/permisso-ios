import SwiftUI
import PermissoWebView
import os.log

@main
struct ExampleApp: App {
    
    init() {
        // Conditionally preload WebKit processes during app initialization
        // Skip preloading if we're in a problematic environment
        #if !targetEnvironment(macCatalyst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PermissoWebView.preloadWebKitProcesses()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
