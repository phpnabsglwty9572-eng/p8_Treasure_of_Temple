class BallItem {
  BallItem({
    required this.id,
    required this.row,
    required this.col,
    required this.colorId,
  });

  final String id;
  int row;
  int col;
  final int colorId;

  BallItem copyWith({int? row, int? col}) {
    return BallItem(
      id: id,
      row: row ?? this.row,
      col: col ?? this.col,
      colorId: colorId,
    );
  }
}

class DropRecord {
  DropRecord({
    required this.ballId,
    required this.colorId,
    required this.slotIndex,
    required this.row,
    required this.col,
  });

  final String ballId;
  final int colorId;
  final int slotIndex;
  final int row;
  final int col;
}
