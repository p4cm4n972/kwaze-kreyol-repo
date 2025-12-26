'use client';

import { useState, useEffect, useCallback } from 'react';
import { generateWordSearch, getRandomWordsFromDict, type WordSearchGrid, type Word } from '@/lib/games/word-search-generator';

interface GameBoardProps {
  dictData: any[];
}

export default function GameBoard({ dictData }: GameBoardProps) {
  const [gameData, setGameData] = useState<WordSearchGrid | null>(null);
  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [foundWords, setFoundWords] = useState<Set<string>>(new Set());
  const [isSelecting, setIsSelecting] = useState(false);
  const [score, setScore] = useState(0);
  const [timeElapsed, setTimeElapsed] = useState(0);
  const [isGameComplete, setIsGameComplete] = useState(false);

  // Initialiser le jeu
  useEffect(() => {
    startNewGame();
  }, [dictData]);

  // Timer
  useEffect(() => {
    if (!isGameComplete && gameData) {
      const timer = setInterval(() => {
        setTimeElapsed(t => t + 1);
      }, 1000);
      return () => clearInterval(timer);
    }
  }, [isGameComplete, gameData]);

  const startNewGame = () => {
    const words = getRandomWordsFromDict(dictData, 10);
    const grid = generateWordSearch(words, 12);
    setGameData(grid);
    setSelectedCells(new Set());
    setFoundWords(new Set());
    setScore(0);
    setTimeElapsed(0);
    setIsGameComplete(false);
  };

  const cellKey = (row: number, col: number) => `${row}-${col}`;

  const handleMouseDown = (row: number, col: number) => {
    setIsSelecting(true);
    setSelectedCells(new Set([cellKey(row, col)]));
  };

  const handleMouseEnter = (row: number, col: number) => {
    if (isSelecting) {
      setSelectedCells(prev => new Set([...prev, cellKey(row, col)]));
    }
  };

  const handleMouseUp = useCallback(() => {
    if (!gameData || !isSelecting) return;

    // Vérifier si la sélection forme un mot
    const selectedWord = Array.from(selectedCells)
      .sort((a, b) => {
        const [r1, c1] = a.split('-').map(Number);
        const [r2, c2] = b.split('-').map(Number);
        return r1 - r2 || c1 - c2;
      })
      .map(key => {
        const [row, col] = key.split('-').map(Number);
        return gameData.grid[row][col];
      })
      .join('');

    // Chercher le mot dans la liste
    const foundWord = gameData.words.find(w =>
      w.word === selectedWord && !foundWords.has(w.word)
    );

    if (foundWord) {
      setFoundWords(prev => new Set([...prev, foundWord.word]));
      setScore(prev => prev + foundWord.word.length * 10);

      // Vérifier si tous les mots sont trouvés
      if (foundWords.size + 1 === gameData.words.length) {
        setIsGameComplete(true);
      }
    } else {
      setSelectedCells(new Set());
    }

    setIsSelecting(false);
  }, [gameData, selectedCells, foundWords, isSelecting]);

  useEffect(() => {
    document.addEventListener('mouseup', handleMouseUp);
    return () => document.removeEventListener('mouseup', handleMouseUp);
  }, [handleMouseUp]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  if (!gameData) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-white text-xl">Chargement...</div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-6xl mx-auto">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Grille de jeu */}
        <div className="lg:col-span-2">
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-4 md:p-6 border border-white/20 shadow-2xl">
            {/* Stats */}
            <div className="flex justify-between items-center mb-4 text-white">
              <div className="text-lg font-bold">
                ⏱️ {formatTime(timeElapsed)}
              </div>
              <div className="text-lg font-bold">
                🎯 Score: {score}
              </div>
              <div className="text-lg font-bold">
                ✅ {foundWords.size}/{gameData.words.length}
              </div>
            </div>

            {/* Grille */}
            <div
              className="grid gap-1 select-none"
              style={{ gridTemplateColumns: `repeat(${gameData.gridSize}, minmax(0, 1fr))` }}
            >
              {gameData.grid.map((row, rowIndex) =>
                row.map((letter, colIndex) => {
                  const key = cellKey(rowIndex, colIndex);
                  const isSelected = selectedCells.has(key);
                  const isInFoundWord = gameData.words.some(w =>
                    foundWords.has(w.word) &&
                    w.cells.some(c => c.row === rowIndex && c.col === colIndex)
                  );

                  return (
                    <div
                      key={key}
                      className={`
                        aspect-square flex items-center justify-center
                        text-sm sm:text-base md:text-lg font-bold rounded
                        cursor-pointer transition-all duration-150
                        ${isInFoundWord
                          ? 'bg-madras-green text-white'
                          : isSelected
                            ? 'bg-madras-yellow text-black'
                            : 'bg-white/20 text-white hover:bg-white/30'
                        }
                      `}
                      onMouseDown={() => handleMouseDown(rowIndex, colIndex)}
                      onMouseEnter={() => handleMouseEnter(rowIndex, colIndex)}
                    >
                      {letter}
                    </div>
                  );
                })
              )}
            </div>

            {/* Nouvelle partie */}
            <button
              onClick={startNewGame}
              className="w-full mt-4 bg-madras-yellow text-black px-6 py-3 rounded-lg font-bold hover:bg-madras-orange transition-all duration-300"
            >
              🔄 Nouvelle partie
            </button>
          </div>
        </div>

        {/* Liste des mots */}
        <div className="lg:col-span-1">
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-4 md:p-6 border border-white/20 shadow-2xl">
            <h3 className="text-xl font-bold text-madras-yellow mb-4">
              Mots à trouver
            </h3>
            <div className="space-y-2">
              {gameData.words.map((word, index) => (
                <div
                  key={index}
                  className={`
                    p-3 rounded-lg text-sm md:text-base font-semibold transition-all
                    ${foundWords.has(word.word)
                      ? 'bg-madras-green text-white line-through'
                      : 'bg-white/20 text-white'
                    }
                  `}
                >
                  {word.word}
                </div>
              ))}
            </div>

            {/* Message de victoire */}
            {isGameComplete && (
              <div className="mt-6 p-4 bg-madras-yellow text-black rounded-lg text-center font-bold">
                <div className="text-2xl mb-2">🎉 Bravo !</div>
                <div className="text-sm">
                  Temps: {formatTime(timeElapsed)}<br />
                  Score: {score} points
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
