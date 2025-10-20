import SwiftUI

struct ContentView: View {
    let permissoURL = URL(string: "https://s.prms.io/m/5dapwREh")!

    var body: some View {
        PermissoWebViewRepresentable(url: permissoURL)
    }
}
