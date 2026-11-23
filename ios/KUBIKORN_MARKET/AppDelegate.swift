import UIKit
import WebKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor(red: 8.0/255.0, green: 5.0/255.0, blue: 16.0/255.0, alpha: 1)
        window.rootViewController = MarketViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class MarketViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 8.0/255.0, green: 5.0/255.0, blue: 16.0/255.0, alpha: 1)

        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = view.backgroundColor
        webView.isOpaque = false
        webView.scrollView.backgroundColor = view.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let page = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www"),
           let readAccess = Bundle.main.resourceURL?.appendingPathComponent("www", isDirectory: true) {
            webView.loadFileURL(page, allowingReadAccessTo: readAccess)
        } else {
            showMissingAssetsMessage()
        }
    }

    private func showMissingAssetsMessage() {
        let html = "<html><body style='background:#080510;color:#f5eaff;font:17px -apple-system;padding:32px'><h2>KUBIKORN_MARKET</h2><p>Nie znaleziono lokalnych plików aplikacji. Zainstaluj ponownie aplikację.</p></body></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.isFileURL || url.scheme == "about" {
            decisionHandler(.allow)
            return
        }
        if ["https", "http", "tg", "whatsapp"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        decisionHandler(.cancel)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}
