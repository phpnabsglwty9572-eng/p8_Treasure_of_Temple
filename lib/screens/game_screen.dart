import 'package:flutter/material.dart';

import '../game/ball_item.dart';
import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../services/sound_service.dart';
import '../widgets/design_stage.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _game;
  int _lastToastToken = 0;

  @override
  void initState() {
    super.initState();
    _game = GameController(
      onSfx: (name) => SoundService.instance.playSfx(name),
    );
    _game.addListener(_onGameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.startNewGame();
    });
  }

  void _onGameChanged() {
    if (!mounted) return;
    setState(() {});
    if (_game.toast != null && _game.toastToken != _lastToastToken) {
      _lastToastToken = _game.toastToken;
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) _game.clearToast();
      });
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A120C),
      body: DesignStage(
        backgroundAsset: 'assets/images/GameBG_01.png',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: GameConstants.chromeLeft,
              top: GameConstants.chromeTop,
              width: GameConstants.chromeWidth,
              height: GameConstants.chromeHeight,
              child: Image.asset(
                'assets/images/GameBG_02.png',
                fit: BoxFit.fill,
              ),
            ),
            _StatLabel(
              left: GameConstants.ballsLabelX,
              top: GameConstants.statsLabelY,
              value: '${_game.clearedBalls}',
            ),
            _StatLabel(
              left: GameConstants.scoreLabelX,
              top: GameConstants.statsLabelY,
              value: '${_game.score}',
            ),
            Positioned(
              left: GameConstants.slotCenterX -
                  (GameConstants.gridStep * 2 + GameConstants.itemSize) / 2,
              top: GameConstants.slotCenterY - GameConstants.itemSize / 2,
              width: GameConstants.gridStep * 2 + GameConstants.itemSize,
              height: GameConstants.itemSize,
              child: _SlotPreview(game: _game),
            ),
            Positioned(
              left: GameConstants.boardLeft,
              top: GameConstants.boardTop,
              width: GameConstants.boardSize,
              height: GameConstants.boardSize,
              child: _Board(game: _game, side: GameConstants.boardSize),
            ),
            const Positioned.fill(child: _AudioButtons()),
            Positioned(
              left: GameConstants.homeBtnX - GameConstants.homeBtnSize / 2,
              top: GameConstants.homeBtnY - GameConstants.homeBtnSize / 2,
              width: GameConstants.homeBtnSize,
              height: GameConstants.homeBtnSize,
              child: GestureDetector(
                onTap: () async {
                  await SoundService.instance.playButton();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: Image.asset(
                  'assets/images/HomeBtn_01.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: GameConstants.undoBtnX - GameConstants.actionBtnWidth / 2,
              top: GameConstants.actionBtnY - GameConstants.actionBtnHeight / 2,
              width: GameConstants.actionBtnWidth,
              height: GameConstants.actionBtnHeight,
              child: GestureDetector(
                onTap: () async {
                  await SoundService.instance.playButton();
                  await _game.undo();
                },
                child: Image.asset(
                  'assets/images/UndoBtn_01.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned(
              left: GameConstants.resetBtnX - GameConstants.actionBtnWidth / 2,
              top: GameConstants.actionBtnY - GameConstants.actionBtnHeight / 2,
              width: GameConstants.actionBtnWidth,
              height: GameConstants.actionBtnHeight,
              child: GestureDetector(
                onTap: () async {
                  await SoundService.instance.playButton();
                  await _game.reset();
                },
                child: Image.asset(
                  'assets/images/ResetBtn_01.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            _ToastBanner(text: _game.toast),
            if (_game.gameOver)
              _GameOverOverlay(
                score: _game.score,
                balls: _game.clearedBalls,
                onRestart: () => _game.startNewGame(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  const _StatLabel({
    required this.left,
    required this.top,
    required this.value,
  });

  final double left;
  final double top;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left - 60,
      top: top - 28,
      width: 120,
      height: 56,
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            color: GameConstants.scoreColor,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AudioButtons extends StatelessWidget {
  const _AudioButtons();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SoundService.instance,
      builder: (context, _) {
        final sound = SoundService.instance;
        return Stack(
          children: [
            Positioned(
              left: GameConstants.soundBtnX - GameConstants.audioBtnSize / 2,
              top: GameConstants.audioBtnY - GameConstants.audioBtnSize / 2,
              width: GameConstants.audioBtnSize,
              height: GameConstants.audioBtnSize,
              child: _IconToggle(
                onAsset: 'assets/images/SoundBtn_01.png',
                offAsset: 'assets/images/SoundBtn_02.png',
                enabled: sound.sfxEnabled,
                onTap: () async {
                  final next = !sound.sfxEnabled;
                  await SoundService.instance.setSfxEnabled(next);
                  if (next) {
                    await SoundService.instance.playButton();
                  }
                },
              ),
            ),
            Positioned(
              left: GameConstants.musicBtnX - GameConstants.audioBtnSize / 2,
              top: GameConstants.audioBtnY - GameConstants.audioBtnSize / 2,
              width: GameConstants.audioBtnSize,
              height: GameConstants.audioBtnSize,
              child: _IconToggle(
                onAsset: 'assets/images/MusicBtn_01.png',
                offAsset: 'assets/images/MusicBtn_02.png',
                enabled: sound.musicEnabled,
                onTap: () async {
                  final next = !sound.musicEnabled;
                  // Play click before pausing BGM when turning music off.
                  if (sound.sfxEnabled) {
                    await SoundService.instance.playButton();
                  }
                  await SoundService.instance.setMusicEnabled(next);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.onAsset,
    required this.offAsset,
    required this.enabled,
    required this.onTap,
  });
  final String onAsset;
  final String offAsset;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(enabled ? onAsset : offAsset, fit: BoxFit.contain),
    );
  }
}

class _SlotPreview extends StatelessWidget {
  const _SlotPreview({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(GameConstants.spawnCountPerTurn, (i) {
        final colorId = i < game.nextColors.length ? game.nextColors[i] : 0;
        final flying = game.flyingIn.values.any((t) => t.slotIndex == i);
        return Opacity(
          opacity: flying ? 0 : 1,
          child: Image.asset(
            GameConstants.ballAssets[colorId],
            width: GameConstants.itemSize,
            height: GameConstants.itemSize,
          ),
        );
      }),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.game, required this.side});
  final GameController game;
  final double side;

  Offset cellCenter(int row, int col) => GameConstants.cellCenter(row, col);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final local = d.localPosition;
        final col = (local.dx / GameConstants.gridStep).floor();
        final row = (local.dy / GameConstants.gridStep).floor();
        if (row < 0 ||
            col < 0 ||
            row >= GameConstants.gridCount ||
            col >= GameConstants.gridCount) {
          return;
        }
        final occupied = game.grid[row][col];
        if (occupied != null) {
          game.selectBall(occupied);
        } else {
          game.onTapCell(row, col);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final ball in game.ballsOnBoard)
            _BallWidget(
              key: ValueKey('ball_${ball.id}'),
              ball: ball,
              selected: game.selected?.id == ball.id,
              clearing: game.clearingIds.contains(ball.id),
              moving: game.movingBallId == ball.id,
              moveFrom: game.movingBallId == ball.id ? game.movingFrom : null,
              movePath: game.movingBallId == ball.id ? game.movingPath : null,
              onTap: () => game.selectBall(ball),
            ),
          for (final e in game.flyingIn.entries)
            _FlyInBall(
              key: ValueKey('fly_${e.key}'),
              colorId: e.value.colorId,
              slotIndex: e.value.slotIndex,
              end: cellCenter(e.value.row, e.value.col),
            ),
          for (final e in game.flyingUndo.entries)
            _FlyUndoBall(
              key: ValueKey('undo_${e.key}'),
              colorId: e.value.colorId,
              slotIndex: e.value.slotIndex,
              start: cellCenter(e.value.row, e.value.col),
            ),
        ],
      ),
    );
  }
}

class _BallWidget extends StatelessWidget {
  const _BallWidget({
    super.key,
    required this.ball,
    required this.selected,
    required this.clearing,
    required this.moving,
    required this.moveFrom,
    required this.movePath,
    required this.onTap,
  });

  final BallItem ball;
  final bool selected;
  final bool clearing;
  final bool moving;
  final (int, int)? moveFrom;
  final List<(int, int)>? movePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget child = Image.asset(
      GameConstants.ballAssets[ball.colorId],
      width: GameConstants.itemSize,
      height: GameConstants.itemSize,
    );

    child = AnimatedScale(
      scale: selected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: child,
    );

    if (clearing) {
      child = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: GameConstants.clearDuration,
        builder: (_, v, c) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.2 + 0.8 * v, child: c),
        ),
        child: child,
      );
    }

    if (moving && moveFrom != null && movePath != null && movePath!.isNotEmpty) {
      final points = <Offset>[
        GameConstants.cellCenter(moveFrom!.$1, moveFrom!.$2),
        for (final cell in movePath!) GameConstants.cellCenter(cell.$1, cell.$2),
      ];
      return _PathMoveBall(
        key: ValueKey('move_${ball.id}_${movePath!.length}'),
        points: points,
        stepDuration: GameConstants.moveStepDuration,
        child: child,
      );
    }

    final center = GameConstants.cellCenter(ball.row, ball.col);
    return Positioned(
      left: center.dx - GameConstants.itemSize / 2,
      top: center.dy - GameConstants.itemSize / 2,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

/// Animates a ball along grid waypoints, one cell per [stepDuration] (Cocos-style).
class _PathMoveBall extends StatefulWidget {
  const _PathMoveBall({
    super.key,
    required this.points,
    required this.stepDuration,
    required this.child,
  });

  final List<Offset> points;
  final Duration stepDuration;
  final Widget child;

  @override
  State<_PathMoveBall> createState() => _PathMoveBallState();
}

class _PathMoveBallState extends State<_PathMoveBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final steps = (widget.points.length - 1).clamp(1, 100);
    _controller = AnimationController(
      vsync: this,
      duration: widget.stepDuration * steps,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _positionFor(double t) {
    final points = widget.points;
    if (points.length == 1) return points.first;
    final segments = points.length - 1;
    final scaled = (t * segments).clamp(0.0, segments.toDouble());
    final index = scaled.floor().clamp(0, segments - 1);
    final localT = scaled - index;
    return Offset.lerp(points[index], points[index + 1], localT)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final p = _positionFor(_controller.value);
        return Positioned(
          left: p.dx - GameConstants.itemSize / 2,
          top: p.dy - GameConstants.itemSize / 2,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _FlyInBall extends StatelessWidget {
  const _FlyInBall({
    super.key,
    required this.colorId,
    required this.slotIndex,
    required this.end,
  });

  final int colorId;
  final int slotIndex;
  final Offset end;

  @override
  Widget build(BuildContext context) {
    final start = GameConstants.slotPosInBoard(slotIndex);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConstants.slotFlyDuration,
      curve: Curves.easeOut,
      builder: (_, t, child) {
        final p = Offset.lerp(start, end, t)!;
        return Positioned(
          left: p.dx - GameConstants.itemSize / 2,
          top: p.dy - GameConstants.itemSize / 2,
          child: child!,
        );
      },
      child: Image.asset(
        GameConstants.ballAssets[colorId],
        width: GameConstants.itemSize,
        height: GameConstants.itemSize,
      ),
    );
  }
}

class _FlyUndoBall extends StatelessWidget {
  const _FlyUndoBall({
    super.key,
    required this.colorId,
    required this.slotIndex,
    required this.start,
  });

  final int colorId;
  final int slotIndex;
  final Offset start;

  @override
  Widget build(BuildContext context) {
    final end = GameConstants.slotPosInBoard(slotIndex);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConstants.undoFlyDuration,
      curve: Curves.easeOut,
      builder: (_, t, child) {
        final p = Offset.lerp(start, end, t)!;
        return Positioned(
          left: p.dx - GameConstants.itemSize / 2,
          top: p.dy - GameConstants.itemSize / 2,
          child: child!,
        );
      },
      child: Image.asset(
        GameConstants.ballAssets[colorId],
        width: GameConstants.itemSize,
        height: GameConstants.itemSize,
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  const _ToastBanner({required this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    final visible = text != null && text!.isNotEmpty;
    return Positioned(
      left: (GameConstants.designWidth - 1000) / 2,
      top: GameConstants.designHeight / 2 - 100,
      width: 1000,
      height: 200,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 120 : 180),
          child: Container(
            color: const Color.fromARGB(109, 5, 0, 0),
            alignment: Alignment.center,
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.balls,
    required this.onRestart,
  });

  final int score;
  final int balls;
  final VoidCallback onRestart;

  // From Cocos ui_over / GameOver_01.png (548x364).
  static const double _panelW = 548;
  static const double _panelH = 364;
  static const double _panelCenterY = GameConstants.designHeight / 2 - 57.398;
  static const double _restartCenterY = GameConstants.designHeight / 2 + 115.483;
  static const double _ballsCenterX = 320;
  static const double _ballsCenterY = 175;
  static const double _scoreCenterX = 320;
  static const double _scoreCenterY = 248;

  @override
  Widget build(BuildContext context) {
    final panelLeft = (GameConstants.designWidth - _panelW) / 2;
    final panelTop = _panelCenterY - _panelH / 2;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          children: [
            Positioned(
              left: panelLeft,
              top: panelTop,
              width: _panelW,
              height: _panelH,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/GameOver_01.png',
                    width: _panelW,
                    height: _panelH,
                    fit: BoxFit.fill,
                  ),
                  _ValueLabel(
                    left: _ballsCenterX,
                    top: _ballsCenterY,
                    value: '$balls',
                  ),
                  _ValueLabel(
                    left: _scoreCenterX,
                    top: _scoreCenterY,
                    value: '$score',
                  ),
                ],
              ),
            ),
            Positioned(
              left: (GameConstants.designWidth - 244) / 2,
              top: _restartCenterY - 59,
              width: 244,
              height: 118,
              child: GestureDetector(
                onTap: () async {
                  await SoundService.instance.playButton();
                  onRestart();
                },
                child: Image.asset(
                  'assets/images/RestartBtn_01.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel({
    required this.left,
    required this.top,
    required this.value,
  });

  final double left;
  final double top;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left - 70,
      top: top - 30,
      width: 140,
      height: 60,
      child: Center(
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GameConstants.scoreColor,
            fontSize: 50,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
