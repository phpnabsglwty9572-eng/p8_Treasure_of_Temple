import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'privacy_policy_config.dart';

/// 首页隐私政策全屏 WebView。
///
/// 页面可通过 `jsbridge://agree` / `jsbridge://close`（或 `window.jsBridge.postMessage`）
/// 回传结果；也可点右上角关闭。
class PrivacyWebPage extends StatefulWidget {
  const PrivacyWebPage({super.key});

  @override
  State<PrivacyWebPage> createState() => _PrivacyWebPageState();
}

class _PrivacyWebPageState extends State<PrivacyWebPage> {
  static const _bridgeScript = r'''
!function(){if(window.__FJB__)return!0;function t(t){if(void 0===t||null===t||""===t)return"{}";if("string"==typeof t)return t;try{return JSON.stringify(t)}catch(e){return String(t)}}function e(e,n){var i=encodeURIComponent(e||""),o=encodeURIComponent(t(n));return"jsbridge://"+i+"?params="+o}function n(){if(!r&&a.length){r=!0;var t=a.shift(),e=null;try{(e=document.createElement("iframe")).style.display="none",e.style.width="0px",e.style.height="0px",e.style.border="0",e.src=t.url,(document.documentElement||document.body).appendChild(e)}catch(t){return r=!1,void(a.length>0&&setTimeout(n,0))}setTimeout(function(){try{e&&e.parentNode&&e.parentNode.removeChild(e)}catch(t){}r=!1,a.length>0&&setTimeout(n,0)},s)}}function i(i,o){try{a.push({id:c++,event:i||"",params:t(o),url:e(i,o)}),n()}catch(t){}}var a=[],r=!1,c=1,s=30;return window.__FJB__=!0,window.jsBridge=window.jsBridge||{},window.jsBridge.postMessage=i,!0}();
''';

  InAppWebViewController? _controller;
  double _progress = 0;
  bool _closed = false;
  String? _error;

  String get _loadUrl => _webviewUrl(PrivacyPolicyConfig.url.trim());

  static String _webviewUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('docs.google.com')) return url;
    final path = uri.path.replaceFirst(RegExp(r'/(edit|view)$'), '/preview');
    return uri.replace(path: path, query: '').toString();
  }

  void _finish(String result) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  void _handleJsBridgeUrl(Uri uri) {
    if (uri.scheme != 'jsbridge') return;
    final event = uri.host.isNotEmpty
        ? uri.host
        : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
    switch (event) {
      case 'agree':
        _finish('agree');
        break;
      case 'close':
        _finish('close');
        break;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    final url = _loadUrl;
    if (url.isEmpty) return;
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    final url = _loadUrl;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          title: const Text('Privacy Policy'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _finish('close'),
          ),
        ),
        body: SafeArea(
          top: false,
          child: url.isEmpty
              ? const Center(child: Text('Please set PrivacyPolicyConfig.url'))
              : Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(url)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        useShouldOverrideUrlLoading: true,
                        isInspectable: kDebugMode,
                        sharedCookiesEnabled: true,
                        thirdPartyCookiesEnabled: true,
                        supportZoom: true,
                        preferredContentMode: UserPreferredContentMode.MOBILE,
                        transparentBackground: false,
                        disableDefaultErrorPage: true,
                      ),
                      onWebViewCreated: (controller) {
                        _controller = controller;
                      },
                      onLoadStart: (controller, _) {
                        if (!mounted) return;
                        setState(() => _error = null);
                      },
                      onLoadStop: (controller, _) async {
                        await controller.evaluateJavascript(source: _bridgeScript);
                      },
                      onProgressChanged: (controller, progress) {
                        if (!mounted) return;
                        setState(() => _progress = progress / 100);
                      },
                      onReceivedError: (controller, request, error) {
                        if (request.isForMainFrame == false) return;
                        if (!mounted) return;
                        setState(() {
                          _error = error.description.isNotEmpty
                              ? error.description
                              : 'Failed to load Privacy Policy';
                        });
                      },
                      onReceivedHttpError: (controller, request, response) {
                        if (request.isForMainFrame == false) return;
                        final code = response.statusCode ?? 0;
                        if (code < 400) return;
                        if (!mounted) return;
                        setState(() {
                          _error = 'HTTP $code';
                        });
                      },
                      shouldOverrideUrlLoading: (controller, action) async {
                        final uri = action.request.url;
                        if (uri == null) {
                          return NavigationActionPolicy.ALLOW;
                        }
                        if (uri.scheme == 'jsbridge') {
                          _handleJsBridgeUrl(uri);
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (action.isForMainFrame == false) {
                          return NavigationActionPolicy.ALLOW;
                        }
                        const allowed = {
                          'http',
                          'https',
                          'about',
                          'data',
                          'file',
                          'blob',
                        };
                        if (!allowed.contains(uri.scheme)) {
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                    ),
                    if (_progress < 1 && _error == null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(value: _progress),
                      ),
                    if (_error != null)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Unable to load Privacy Policy',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _reload,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
