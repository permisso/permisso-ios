import SwiftUI

struct ContentView: View {
    let permissoURL = URL(string: "https://s.prms.io/m/5dapwREh")!

    var body: some View {
        // Use our custom representable view.
        // The `.ignoresSafeArea()` makes it go edge-to-edge.
        PermissoWebViewRepresentable(url: permissoURL)
            .ignoresSafeArea()
    }
}
