import 'dart:math';

import 'package:flutter/foundation.dart';

import 'ball_item.dart';
import 'game_constants.dart';

typedef SfxPlayer = void Function(String name);

class GameController extends ChangeNotifier {
  GameController({this.onSfx});

  final SfxPlayer? onSfx;
  final _rng = Random();

  late List<List<BallItem?>> _grid;
  final Map<String, BallItem> _balls = {};
  BallItem? selected;
  List<int> nextColors = [];
  List<int> _activeColorPool = [];
  List<DropRecord> _lastDropBatch = [];
  bool _undoneForCurrentDrop = false;

  int score = 0;
  int clearedBalls = 0;
  bool busy = false;
  bool gameOver = false;
  String? toast;
  int toastToken = 0;

  /// Path animation for a moving ball: list of grid cells after leaving start.
  List<(int, int)>? movingPath;
  (int, int)? movingFrom;
  String? movingBallId;

  /// Balls currently flying from slot -> board (id -> target cell + color).
  final Map<String, ({int row, int col, int colorId, int slotIndex})> flyingIn = {};

  /// Ball ids currently clearing (scale/fade).
  final Set<String> clearingIds = {};

  /// Balls flying back to slot on undo: id -> (slotIndex, colorId, fromRow, fromCol)
  final Map<String, ({int slotIndex, int colorId, int row, int col})> flyingUndo = {};

  int _idSeq = 0;

  List<List<BallItem?>> get grid => _grid;
  Iterable<BallItem> get ballsOnBoard => _balls.values.where(
        (b) =>
            b.row >= 0 &&
            !flyingIn.containsKey(b.id) &&
            !flyingUndo.containsKey(b.id) &&
            !clearingIds.contains(b.id),
      );

  Future<void> startNewGame() async {
    _initGrid();
    _balls.clear();
    selected = null;
    score = 0;
    clearedBalls = 0;
    gameOver = false;
    _lastDropBatch = [];
    _undoneForCurrentDrop = false;
    movingPath = null;
    movingFrom = null;
    movingBallId = null;
    flyingIn.clear();
    flyingUndo.clear();
    clearingIds.clear();
    _initActiveColorPool();
    _prepareNextColors();
    notifyListeners();
    busy = true;
    notifyListeners();
    await _spawnFromSlots();
    busy = false;
    notifyListeners();
  }

  void _initGrid() {
    _grid = List.generate(
      GameConstants.gridCount,
      (_) => List<BallItem?>.filled(GameConstants.gridCount, null),
    );
  }

  void _initActiveColorPool() {
    _activeColorPool = [];
    final colorCount = GameConstants.ballAssets.length;
    final target = min(GameConstants.activeColorKindCount, colorCount);
    final picked = <int>{};
    while (picked.length < target) {
      picked.add(_rng.nextInt(colorCount));
    }
    _activeColorPool = picked.toList();
  }

  void _prepareNextColors() {
    nextColors = List.generate(
      GameConstants.spawnCountPerTurn,
      (_) => _randomColorId(),
    );
  }

  int _randomColorId() {
    if (_activeColorPool.isNotEmpty) {
      return _activeColorPool[_rng.nextInt(_activeColorPool.length)];
    }
    return _rng.nextInt(GameConstants.ballAssets.length);
  }

  void selectBall(BallItem item) {
    if (busy || gameOver) return;
    if (selected?.id == item.id) return;
    onSfx?.call('sound_click_item');
    selected = item;
    notifyListeners();
  }

  Future<void> onTapCell(int row, int col) async {
    if (gameOver || busy || selected == null) return;
    if (_grid[row][col] != null) return;
    await _tryMoveTo(row, col);
  }

  Future<void> _tryMoveTo(int toRow, int toCol) async {
    final from = selected!;
    final fromRow = from.row;
    final fromCol = from.col;
    final path = _findShortestPath(fromRow, fromCol, toRow, toCol);
    if (path.isEmpty) {
      _showToast('Cannot move.');
      onSfx?.call('sound_cannot_move');
      return;
    }

    busy = true;
    notifyListeners();

    _grid[fromRow][fromCol] = null;
    _grid[toRow][toCol] = from;
    from.row = toRow;
    from.col = toCol;
    selected = null;

    movingBallId = from.id;
    movingFrom = (fromRow, fromCol);
    movingPath = path;
    notifyListeners();
    await Future.delayed(
      GameConstants.moveStepDuration * path.length + const Duration(milliseconds: 20),
    );
    movingBallId = null;
    movingFrom = null;
    movingPath = null;
    notifyListeners();

    final clearSet = _collectLinesAt(toRow, toCol);
    if (clearSet.isNotEmpty) {
      onSfx?.call('sound_match');
      _addClearScore(clearSet.length);
      await _clearItems(clearSet);
    } else {
      await _spawnFromSlots();
    }

    busy = false;
    notifyListeners();
  }

  Future<void> _spawnFromSlots() async {
    final empties = _getEmptyCells();
    if (empties.isEmpty) return;

    final spawnColors = List<int>.from(nextColors);
    final putCount = min(spawnColors.length, empties.length);
    final targets = <({int row, int col, int colorId, int slotIndex})>[];
    for (var i = 0; i < putCount; i++) {
      final idx = _rng.nextInt(empties.length);
      final cell = empties.removeAt(idx);
      targets.add((
        row: cell.$1,
        col: cell.$2,
        colorId: spawnColors[i],
        slotIndex: i,
      ));
    }

    final batch = <DropRecord>[];
    flyingIn.clear();
    for (final t in targets) {
      final id = 'b${_idSeq++}';
      final ball = BallItem(id: id, row: t.row, col: t.col, colorId: t.colorId);
      _balls[id] = ball;
      flyingIn[id] = t;
    }
    notifyListeners();
    await Future.delayed(GameConstants.slotFlyDuration + const Duration(milliseconds: 30));

    final flyEntries = Map.of(flyingIn);
    flyingIn.clear();
    for (final e in flyEntries.entries) {
      final ball = _balls[e.key];
      if (ball == null) continue;
      final t = e.value;
      ball.row = t.row;
      ball.col = t.col;
      _grid[t.row][t.col] = ball;
      batch.add(DropRecord(
        ballId: ball.id,
        colorId: t.colorId,
        slotIndex: t.slotIndex,
        row: t.row,
        col: t.col,
      ));
    }
    notifyListeners();

    final allClear = <BallItem>[];
    for (var r = 0; r < GameConstants.gridCount; r++) {
      for (var c = 0; c < GameConstants.gridCount; c++) {
        if (_grid[r][c] == null) continue;
        for (final item in _collectLinesAt(r, c)) {
          if (!allClear.any((x) => x.id == item.id)) {
            allClear.add(item);
          }
        }
      }
    }
    if (allClear.isNotEmpty) {
      onSfx?.call('sound_match');
      _addClearScore(allClear.length);
      await _clearItems(allClear);
    }

    _prepareNextColors();
    _lastDropBatch = batch.where((r) => _balls.containsKey(r.ballId)).toList();
    _undoneForCurrentDrop = false;
    _checkGameOver();
    notifyListeners();
  }

  Future<void> undo() async {
    if (busy || gameOver) return;
    if (_undoneForCurrentDrop) {
      _showToast('This drop has already been undone.');
      return;
    }
    if (_lastDropBatch.isEmpty) {
      _showToast('No undo available.');
      return;
    }
    if (score < GameConstants.undoCostScore) {
      _showToast('Undo costs ${GameConstants.undoCostScore} points. Not enough score.');
      return;
    }

    busy = true;
    selected = null;
    notifyListeners();

    final backColors = List<int>.generate(
      GameConstants.spawnCountPerTurn,
      (_) => _randomColorId(),
    );

    flyingUndo.clear();
    for (final rec in _lastDropBatch) {
      backColors[rec.slotIndex] = rec.colorId;
      final ball = _balls[rec.ballId];
      if (ball == null) continue;
      if (_grid[ball.row][ball.col]?.id == ball.id) {
        _grid[ball.row][ball.col] = null;
      }
      flyingUndo[ball.id] = (
        slotIndex: rec.slotIndex,
        colorId: rec.colorId,
        row: ball.row,
        col: ball.col,
      );
    }
    notifyListeners();
    await Future.delayed(GameConstants.undoFlyDuration + const Duration(milliseconds: 30));

    for (final id in flyingUndo.keys.toList()) {
      _balls.remove(id);
    }
    flyingUndo.clear();

    score -= GameConstants.undoCostScore;
    nextColors = backColors;
    _lastDropBatch = [];
    _undoneForCurrentDrop = true;
    busy = false;
    notifyListeners();
  }

  Future<void> reset() async {
    if (busy) return;
    await startNewGame();
  }

  Future<void> _clearItems(List<BallItem> items) async {
    if (items.isEmpty) return;
    for (final item in items) {
      final r = item.row;
      final c = item.col;
      if (r >= 0 &&
          c >= 0 &&
          r < GameConstants.gridCount &&
          c < GameConstants.gridCount &&
          _grid[r][c]?.id == item.id) {
        _grid[r][c] = null;
      }
      if (selected?.id == item.id) selected = null;
      clearingIds.add(item.id);
    }
    notifyListeners();
    await Future.delayed(GameConstants.clearDuration + const Duration(milliseconds: 20));
    for (final item in items) {
      clearingIds.remove(item.id);
      _balls.remove(item.id);
    }
    notifyListeners();
  }

  List<(int, int)> _getEmptyCells() {
    final empties = <(int, int)>[];
    for (var r = 0; r < GameConstants.gridCount; r++) {
      for (var c = 0; c < GameConstants.gridCount; c++) {
        if (_grid[r][c] == null) empties.add((r, c));
      }
    }
    return empties;
  }

  List<(int, int)> _findShortestPath(int fromRow, int fromCol, int toRow, int toCol) {
    final visited = List.generate(
      GameConstants.gridCount,
      (_) => List<bool>.filled(GameConstants.gridCount, false),
    );
    final prev = List.generate(
      GameConstants.gridCount,
      (_) => List<(int, int)?>.filled(GameConstants.gridCount, null),
    );
    final q = <(int, int)>[(fromRow, fromCol)];
    visited[fromRow][fromCol] = true;
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

    while (q.isNotEmpty) {
      final (r, c) = q.removeAt(0);
      if (r == toRow && c == toCol) break;
      for (final (dr, dc) in dirs) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr < 0 || nr >= GameConstants.gridCount || nc < 0 || nc >= GameConstants.gridCount) {
          continue;
        }
        if (visited[nr][nc]) continue;
        if (_grid[nr][nc] != null && !(nr == toRow && nc == toCol)) continue;
        visited[nr][nc] = true;
        prev[nr][nc] = (r, c);
        q.add((nr, nc));
      }
    }

    if (!visited[toRow][toCol]) return [];
    final path = <(int, int)>[];
    (int, int)? cur = (toRow, toCol);
    while (cur != null) {
      path.add(cur);
      cur = prev[cur.$1][cur.$2];
    }
    final ordered = path.reversed.toList();
    if (ordered.isNotEmpty) ordered.removeAt(0);
    return ordered;
  }

  List<BallItem> _collectLinesAt(int row, int col) {
    final item = _grid[row][col];
    if (item == null) return [];
    final colorId = item.colorId;
    const dirs = [(1, 0), (0, 1), (1, 1), (1, -1)];
    final result = <BallItem>[];
    for (final (dr, dc) in dirs) {
      final line = <BallItem>[item];
      _collectOneDirection(line, row, col, dr, dc, colorId);
      _collectOneDirection(line, row, col, -dr, -dc, colorId);
      if (line.length >= GameConstants.minClearCount) {
        for (final cell in line) {
          if (!result.any((x) => x.id == cell.id)) result.add(cell);
        }
      }
    }
    return result;
  }

  void _collectOneDirection(
    List<BallItem> out,
    int row,
    int col,
    int dr,
    int dc,
    int colorId,
  ) {
    var nr = row + dr;
    var nc = col + dc;
    while (nr >= 0 &&
        nr < GameConstants.gridCount &&
        nc >= 0 &&
        nc < GameConstants.gridCount) {
      final item = _grid[nr][nc];
      if (item == null || item.colorId != colorId) break;
      out.add(item);
      nr += dr;
      nc += dc;
    }
  }

  void _addClearScore(int clearCount) {
    if (clearCount <= 0) return;
    score += _calcScoreByClearCount(clearCount);
    clearedBalls += clearCount;
    _updateDifficultyByScore();
  }

  int _calcScoreByClearCount(int clearCount) {
    switch (clearCount) {
      case 5:
        return 10;
      case 6:
        return 25;
      case 7:
        return 45;
      case 8:
        return 70;
      case 9:
        return 100;
      default:
        if (clearCount > 9) return 100 + (clearCount - 9) * 20;
        return 0;
    }
  }

  void _updateDifficultyByScore() {
    final colorCount = GameConstants.ballAssets.length;
    var targetKindCount = GameConstants.activeColorKindCount;
    for (var i = 0; i < GameConstants.colorUnlockThresholds.length; i++) {
      if (score >= GameConstants.colorUnlockThresholds[i]) {
        targetKindCount = GameConstants.activeColorKindCount + i;
      } else {
        break;
      }
    }
    targetKindCount = min(GameConstants.maxColorKindCount, targetKindCount);
    if (_activeColorPool.length >= targetKindCount) return;

    final candidates = <int>[];
    for (var i = 0; i < colorCount; i++) {
      if (!_activeColorPool.contains(i)) candidates.add(i);
    }
    while (_activeColorPool.length < targetKindCount && candidates.isNotEmpty) {
      final idx = _rng.nextInt(candidates.length);
      _activeColorPool.add(candidates.removeAt(idx));
    }
  }

  void _checkGameOver() {
    if (!_isBoardFull()) return;
    gameOver = true;
    onSfx?.call('sound_over');
    selected = null;
  }

  bool _isBoardFull() {
    for (var r = 0; r < GameConstants.gridCount; r++) {
      for (var c = 0; c < GameConstants.gridCount; c++) {
        if (_grid[r][c] == null) return false;
      }
    }
    return true;
  }

  void _showToast(String text) {
    toast = text;
    toastToken++;
    notifyListeners();
  }

  void clearToast() {
    toast = null;
    notifyListeners();
  }
}
