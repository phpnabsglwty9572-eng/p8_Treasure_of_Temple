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

  double _progress = 0;
  bool _closed = false;

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

  @override
  Widget build(BuildContext context) {
    final url = PrivacyPolicyConfig.url.trim();
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
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        useShouldOverrideUrlLoading: true,
                        isInspectable: kDebugMode,
                      ),
                      onLoadStop: (controller, _) async {
                        await controller.evaluateJavascript(source: _bridgeScript);
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() => _progress = progress / 100);
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
                        if (uri.scheme != 'http' &&
                            uri.scheme != 'https' &&
                            uri.scheme != 'about' &&
                            uri.scheme != 'data' &&
                            uri.scheme != 'file') {
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                    ),
                    if (_progress < 1)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(value: _progress),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
