class Word {
  final String text;
  final List<CellPosition> cells;
  bool found;
  final String? definition; // Traduction/définition du mot
  final String? nature; // Nature grammaticale (nom, verbe, etc.)

  Word({
    required this.text,
    required this.cells,
    this.found = false,
    this.definition,
    this.nature,
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
