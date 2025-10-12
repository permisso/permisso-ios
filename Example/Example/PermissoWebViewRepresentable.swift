import SwiftUI
import WebKit
import PermissoWebView

struct PermissoWebViewRepresentable: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> PermissoWebView {
        let permissoView = PermissoWebView()
        permissoView.load(url: url)
        return permissoView
    }

    func updateUIView(_ uiView: PermissoWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        func findParentViewController(for view: UIView) -> UIViewController? {
            var responder: UIResponder? = view
            while let nextResponder = responder?.next {
                if let vc = nextResponder as? UIViewController {
                    return vc
                }
                responder = nextResponder
            }
            return nil
        }
    }
}
