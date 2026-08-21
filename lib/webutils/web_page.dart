import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:treasure_of_temple/webutils/web_util.dart';

/// 全屏 WebView 页面。
class WebPage extends StatefulWidget {
  const WebPage({super.key, required this.step});

  final WebNextStep step;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  double _progress = 0;
  late final WebUri _startUri;
  bool _handlerAdded = false;

  @override
  void initState() {
    super.initState();
    _startUri = WebUri(widget.step.url);
  }

  void _ensureHandler(InAppWebViewController controller) {
    if (_handlerAdded) {
      return;
    }
    _handlerAdded = true;
    controller.addJavaScriptHandler(
      handlerName: WebUtil.handlerName,
      callback: widget.step.callback,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: _startUri),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  useShouldOverrideUrlLoading: true,
                  isInspectable: kDebugMode,
                ),
                onWebViewCreated: (controller) {
                  _ensureHandler(controller);
                },
                onLoadStop: (controller, url) async {
                  final script = widget.step.script;
                  if (script.isNotEmpty) {
                    await controller.evaluateJavascript(source: script);
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100);
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url;
                  if (url != null &&
                      url.scheme != 'http' &&
                      url.scheme != 'https' &&
                      url.scheme != 'about' &&
                      url.scheme != 'data') {
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
