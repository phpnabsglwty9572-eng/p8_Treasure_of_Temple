import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_constants.dart';

/// Fills any screen (phone / tablet) with the fixed 720×1280 design canvas.
///
/// Uses cover scaling: no letterbox bars; overflow is clipped and centered.
/// UI and background stay aligned because they share one design space.
class DesignStage extends StatelessWidget {
  const DesignStage({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF1A120C),
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sw = constraints.maxWidth;
          final sh = constraints.maxHeight;
          if (sw <= 0 || sh <= 0) {
            return const SizedBox.shrink();
          }

          const dw = GameConstants.designWidth;
          const dh = GameConstants.designHeight;
          final scale = math.max(sw / dw, sh / dh);

          return ClipRect(
            child: SizedBox(
              width: sw,
              height: sh,
              child: Center(
                child: SizedBox(
                  width: dw * scale,
                  height: dh * scale,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: dw,
                      height: dh,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
