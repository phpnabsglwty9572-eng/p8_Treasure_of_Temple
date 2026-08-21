import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// [WebUtil.goToNextStep] 的返回结果。
class WebNextStep {
  const WebNextStep({
    required this.url,
    required this.script,
    required this.callback,
  });

  /// WebView 打开的地址。
  final String url;

  /// 注入到 WebView 的 JavaScript（可通过 [WebUtil.handlerName] 回调 Flutter）。
  final String script;

  /// 注入脚本的回调方法（配合 `addJavaScriptHandler` 注册）。
  final JavaScriptHandlerCallback callback;
}

/// WebView 流程工具。
class WebUtil {
  WebUtil._();

  /// 注入脚本里 `callHandler` 使用的处理器名称。
  ///
  /// 示例（已写在 [goToNextStep] 返回的 script 中）：
  /// `window.flutter_inappwebview.callHandler('webUtilCallback', data);`
  static const String handlerName = 'webUtilCallback';

  /// 进入下一步 Web 流程，返回 WebView 地址、注入脚本与脚本回调。
  ///
  /// 使用方式示意：
  /// ```dart
  /// final step = await WebUtil.goToNextStep();
  /// controller.addJavaScriptHandler(
  ///   handlerName: WebUtil.handlerName,
  ///   callback: step.callback,
  /// );
  /// await controller.loadUrl(urlRequest: URLRequest(url: WebUri(step.url)));
  /// // onLoadStop 后：
  /// await controller.evaluateJavascript(source: step.script);
  /// ```
  static Future<WebNextStep> goToNextStep() async {
    // url 为空 → 正常进游戏；非空 → 打开 WebPage
    const url = '';
    final script =
        '''
(function () {
  try {
    var payload = {
      type: 'webUtilReady',
      href: location.href,
      ts: Date.now()
    };
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('$handlerName', payload);
    }
  } catch (e) {
    console.log('webUtil script error', e);
  }
})();
''';

    return WebNextStep(
      url: url,
      script: script,
      callback: (args) async {
        debugPrint('回调已执行: $args');
        return "回调已执行: $args";
      },
    );
  }
}
