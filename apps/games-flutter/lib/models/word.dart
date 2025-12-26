class Word {
  final String text;
  final List<CellPosition> cells;
  bool found;

  Word({
    required this.text,
    required this.cells,
    this.found = false,
  });
}

class CellPosition {
  final int row;
  final int col;

  CellPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class WordSearchGrid {
  final List<List<String>> grid;
  final List<Word> words;
  final int size;

  WordSearchGrid({
    required this.grid,
    required this.words,
    required this.size,
  });
}
