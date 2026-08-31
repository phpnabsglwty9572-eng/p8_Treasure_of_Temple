import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/game_constants.dart';

/// Fits the fixed 720×1280 design canvas into any screen without stretching.
///
/// UI uses contain scaling so the board, pieces, and buttons keep their
/// original aspect ratio. Optional [backgroundAsset] is drawn behind that
/// canvas with cover, so it fills the full screen (no letterbox bars).
class DesignStage extends StatelessWidget {
  const DesignStage({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.backgroundColor = const Color(0xFF1A120C),
  });

  final Widget child;
  final String? backgroundAsset;
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
          final scale = math.min(sw / dw, sh / dh);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (backgroundAsset != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      backgroundAsset!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              Center(
                child: SizedBox(
                  width: dw * scale,
                  height: dh * scale,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: dw,
                      height: dh,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
