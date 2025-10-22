import SwiftUI
import Permisso

struct ContentView: View {
    let permissoURL = URL(string: "https://s.prms.io/m/5dapwREh")!

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {

                Text("Permisso SDK Example")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("✅ Recommended: Static API")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Easy to use, handles presentation automatically")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Present with Static API") {
                            presentPermissoStaticAPI()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    VStack(spacing: 10) {
                        Text("⚠️ Advanced: Custom Embedding")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("Direct web view access for custom layouts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        NavigationLink("Show Advanced Example") {
                            AdvancedWebViewExample(url: permissoURL)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                VStack(spacing: 8) {
                    Text("Configuration")
                        .font(.headline)

                    Text("The static API is pre-configured to handle messages and external links in an in-app browser.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .navigationTitle("Permisso Example")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func presentPermissoStaticAPI() {
        Permisso.shared.configure { config in
            config.linkBehavior = .customTab
            config.messageHandler = { message in
                print("📨 Static API - Received message: \(message)")
            }
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }

        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        Permisso.shared.present(from: topViewController, url: permissoURL) {
            print("✅ Permisso presentation completed")
        }
    }
}

struct AdvancedWebViewExample: View {
    let url: URL

    var body: some View {
        VStack(spacing: 0) {
            Text("Advanced: Custom PermissoWebView")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.2))

            PermissoWebViewRepresentable(url: url)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
