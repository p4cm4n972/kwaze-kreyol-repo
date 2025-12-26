export interface Word {
  word: string;
  found: boolean;
  cells: { row: number; col: number }[];
}

export interface WordSearchGrid {
  grid: string[][];
  words: Word[];
  gridSize: number;
}

const DIRECTIONS = [
  { dx: 0, dy: 1 },   // horizontal →
  { dx: 1, dy: 0 },   // vertical ↓
  { dx: 1, dy: 1 },   // diagonal ↘
  { dx: 1, dy: -1 },  // diagonal ↙
];

export function generateWordSearch(words: string[], gridSize: number = 12): WordSearchGrid {
  const grid: string[][] = Array(gridSize).fill(null).map(() => Array(gridSize).fill(''));
  const placedWords: Word[] = [];

  // Normaliser et filtrer les mots
  const normalizedWords = words
    .map(w => normalizeCreoleWord(w.toUpperCase()))
    .filter(w => w.length >= 3 && w.length <= gridSize)
    .slice(0, 10); // Limiter à 10 mots max

  // Placer les mots
  for (const word of normalizedWords) {
    const placed = placeWord(grid, word, gridSize);
    if (placed) {
      placedWords.push(placed);
    }
  }

  // Remplir les cases vides avec des lettres aléatoires
  for (let row = 0; row < gridSize; row++) {
    for (let col = 0; col < gridSize; col++) {
      if (!grid[row][col]) {
        grid[row][col] = getRandomLetter();
      }
    }
  }

  return {
    grid,
    words: placedWords,
    gridSize,
  };
}

function placeWord(
  grid: string[][],
  word: string,
  gridSize: number
): Word | null {
  const attempts = 100;

  for (let attempt = 0; attempt < attempts; attempt++) {
    const direction = DIRECTIONS[Math.floor(Math.random() * DIRECTIONS.length)];
    const startRow = Math.floor(Math.random() * gridSize);
    const startCol = Math.floor(Math.random() * gridSize);

    if (canPlaceWord(grid, word, startRow, startCol, direction, gridSize)) {
      const cells: { row: number; col: number }[] = [];

      for (let i = 0; i < word.length; i++) {
        const row = startRow + i * direction.dx;
        const col = startCol + i * direction.dy;
        grid[row][col] = word[i];
        cells.push({ row, col });
      }

      return {
        word,
        found: false,
        cells,
      };
    }
  }

  return null;
}

function canPlaceWord(
  grid: string[][],
  word: string,
  startRow: number,
  startCol: number,
  direction: { dx: number; dy: number },
  gridSize: number
): boolean {
  for (let i = 0; i < word.length; i++) {
    const row = startRow + i * direction.dx;
    const col = startCol + i * direction.dy;

    // Vérifier les limites
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return false;
    }

    // Vérifier si la case est vide ou contient la même lettre
    if (grid[row][col] && grid[row][col] !== word[i]) {
      return false;
    }
  }

  return true;
}

function normalizeCreoleWord(word: string): string {
  // Supprimer les caractères spéciaux et garder seulement les lettres créoles
  return word
    .replace(/[^A-ZÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑòóôõöùúûüèéêëàáâãäåìíîïçñ]/g, '')
    .toUpperCase();
}

function getRandomLetter(): string {
  // Lettres courantes en créole martiniquais
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÉÈÊÀÔÙ';
  return letters[Math.floor(Math.random() * letters.length)];
}

// Fonction pour extraire des mots aléatoires du dictionnaire
export function getRandomWordsFromDict(dictData: any[], count: number = 10): string[] {
  const shuffled = [...dictData].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count).map(item => item.mot);
}
