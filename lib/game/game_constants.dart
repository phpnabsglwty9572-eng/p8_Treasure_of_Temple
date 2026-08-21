import 'package:flutter/material.dart';

class GameConstants {
  /// Cocos design resolution (ui_main / Canvas).
  static const double designWidth = 720;
  static const double designHeight = 1280;

  /// GameBG_02 native size; UI chrome is scaled uniformly to design width.
  static const double chromeAssetWidth = 750;
  static const double chromeAssetHeight = 896;
  static const double uiScale = designWidth / chromeAssetWidth; // 0.96

  static const int gridCount = 10;

  /// Measured from GameBG_02 alpha grid (72px cells, origin at first border).
  static const double gridStepAsset = 72;
  static const double itemSizeAsset = 68;
  static const double gridLeftAsset = 14;
  static const double gridTopAsset = 136;

  static const double gridStep = gridStepAsset * uiScale;
  static const double itemSize = itemSizeAsset * uiScale;
  static const double itemGap = gridStep - itemSize;

  static const int spawnCountPerTurn = 3;
  static const int activeColorKindCount = 3;
  static const int maxColorKindCount = 7;
  static const List<int> colorUnlockThresholds = [0, 100, 180, 280, 400];
  static const int minClearCount = 5;
  static const int undoCostScore = 30;
  static const Duration slotFlyDuration = Duration(milliseconds: 450);
  static const Duration undoFlyDuration = Duration(milliseconds: 350);
  static const Duration moveStepDuration = Duration(milliseconds: 50);
  static const Duration clearDuration = Duration(milliseconds: 160);

  // Chrome: keep aspect ratio; vertically match Cocos GameBG_02 center (y = 53.305).
  static const double chromeWidth = designWidth;
  static const double chromeHeight = chromeAssetHeight * uiScale;
  static const double chromeLeft = 0;
  static const double chromeCenterY = designHeight / 2 - 53.305;
  static const double chromeTop = chromeCenterY - chromeHeight / 2;

  static const double boardLeft = chromeLeft + gridLeftAsset * uiScale;
  static const double boardTop = chromeTop + gridTopAsset * uiScale;
  static const double boardSize = gridStep * gridCount;

  // Header value / preview centers in GameBG_02 asset pixels.
  static const double ballsLabelX = chromeLeft + 113 * uiScale;
  static const double scoreLabelX = chromeLeft + 638 * uiScale;
  static const double statsLabelY = chromeTop + 100 * uiScale;
  static const double slotCenterX = chromeLeft + 376 * uiScale;
  static const double slotCenterY = chromeTop + 86 * uiScale;

  // Audio / action buttons from Cocos scene (design space).
  static const double soundBtnX = 498;
  static const double musicBtnX = 636;
  static const double audioBtnY = 68;
  static const double audioBtnSize = 100;

  /// Top-left home button mirrors music button on the right.
  static const double homeBtnX = designWidth - musicBtnX; // 84
  static const double homeBtnY = audioBtnY;
  static const double homeBtnSize = audioBtnSize;

  static const double undoBtnX = 133.389;
  static const double resetBtnX = 592.522;
  static const double actionBtnY = 1176.98;
  static const double actionBtnWidth = 226;
  static const double actionBtnHeight = 100;

  static const Color scoreColor = Color(0xFFA4FF05);

  static const List<String> ballAssets = [
    'assets/images/Ball_01.png',
    'assets/images/Ball_02.png',
    'assets/images/Ball_03.png',
    'assets/images/Ball_04.png',
    'assets/images/Ball_05.png',
    'assets/images/Ball_06.png',
    'assets/images/Ball_07.png',
  ];

  /// Cell center in board-local coordinates (true geometric center of the cell).
  static Offset cellCenter(int row, int col) {
    return Offset(
      col * gridStep + gridStep * 0.5,
      row * gridStep + gridStep * 0.5,
    );
  }

  /// Preview / fly-in start position in board-local coordinates.
  static Offset slotPosInBoard(int slotIndex) {
    final totalWidth = (spawnCountPerTurn - 1) * gridStep;
    final canvasX = slotCenterX - totalWidth * 0.5 + slotIndex * gridStep;
    return Offset(canvasX - boardLeft, slotCenterY - boardTop);
  }
}
