import SwiftUI
import WebKit
import DesignSystem

/// A full-screen web view that loads the configured Learn URL. Links marked with
/// `data-open-external="true"` are opened via `UIApplication.shared.open(_:)`;
/// all other navigation stays inside the web view.
public struct LearnView: View {
  let url: URL

  public init(url: URL) {
    self.url = url
  }

  public var body: some View {
    WebView(url: url) { url in
      UIApplication.shared.open(url)
    }
    .background(theme.bgPrimary)
  }

  @Environment(Theme.self) private var theme
}

// MARK: - WebView

private struct WebView: UIViewRepresentable {
  let url: URL
  let onExternalLink: (URL) -> Void

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.userContentController.addUserScript(externalLinkUserScript)
    config.userContentController.add(context.coordinator, name: ScriptMessageHandlerName.openExternal)

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = context.coordinator
    webView.backgroundColor = .clear
    webView.isOpaque = false
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    webView.load(URLRequest(url: url))
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onExternalLink: onExternalLink)
  }

  private var externalLinkUserScript: WKUserScript {
    WKUserScript(
      source: Self.clickInterceptorScript,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false
    )
  }

  private enum ScriptMessageHandlerName {
    static let openExternal = "openExternal"
  }

  private static let clickInterceptorScript = """
    (function() {
      document.addEventListener('click', function(event) {
        var target = event.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (!target || target.tagName !== 'A') { return; }
        if (target.getAttribute('data-open-external') !== 'true') { return; }

        var href = target.href;
        if (!href) { return; }

        event.preventDefault();
        event.stopPropagation();

        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.openExternal) {
          window.webkit.messageHandlers.openExternal.postMessage(href);
        }
      }, true);
    })();
    """

  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let onExternalLink: (URL) -> Void

    init(onExternalLink: @escaping (URL) -> Void) {
      self.onExternalLink = onExternalLink
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard message.name == ScriptMessageHandlerName.openExternal,
            let urlString = message.body as? String,
            let url = URL(string: urlString) else { return }
      onExternalLink(url)
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
      decisionHandler(.allow)
    }
  }
}
