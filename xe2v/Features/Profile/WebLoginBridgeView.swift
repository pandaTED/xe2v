import SwiftUI
import WebKit

struct WebLoginBridgeView: UIViewRepresentable {
    let onCookiesCaptured: ([HTTPCookie]) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "CleanV2EX-iOS"
        let url = URL(string: "https://www.v2ex.com/signin")!
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCookiesCaptured: onCookiesCaptured)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onCookiesCaptured: ([HTTPCookie]) -> Void

        init(onCookiesCaptured: @escaping ([HTTPCookie]) -> Void) {
            self.onCookiesCaptured = onCookiesCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let host = webView.url?.host ?? ""
            guard host.contains("v2ex.com") else { return }
            DebugLog.info("web login finished url=\(webView.url?.absoluteString ?? "nil")", category: "LoginWeb")

            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let valid = cookies.filter { $0.domain.contains("v2ex.com") }
                DebugLog.info("web login cookies captured total=\(cookies.count) valid=\(valid.count)", category: "LoginWeb")
                self.onCookiesCaptured(valid)
            }
        }
    }
}
