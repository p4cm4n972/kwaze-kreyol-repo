import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import GameBoard from '@/components/games/MotsMawon/GameBoard';
import { promises as fs } from 'fs';
import path from 'path';

async function getDictionaryData() {
  try {
    const filePath = path.join(process.cwd(), '../../data/dictionnaires/dictionnaire_A.json');
    const fileContents = await fs.readFile(filePath, 'utf8');
    const data = JSON.parse(fileContents);
    return data;
  } catch (error) {
    console.error('Error loading dictionary:', error);
    return [];
  }
}

export default async function MotsMawonPage() {
  const dictData = await getDictionaryData();

  return (
    <>
      <Navbar />
      <section
        className="min-h-screen w-full bg-cover bg-center py-20 md:py-32 px-4 relative bg-responsive"
      >
        {/* Cadres décoratifs */}
        <div className="absolute top-0 left-0 w-32 h-32 md:w-64 md:h-64 opacity-30 md:opacity-50">
          <Image
            src="/images/cadre-haut-gauche.webp"
            alt=""
            width={256}
            height={256}
            className="w-full h-full object-contain"
          />
        </div>
        <div className="absolute top-0 right-0 w-32 h-32 md:w-64 md:h-64 opacity-30 md:opacity-50">
          <Image
            src="/images/cadre-haut-droite.webp"
            alt=""
            width={256}
            height={256}
            className="w-full h-full object-contain"
          />
        </div>

        <div className="max-w-7xl mx-auto relative z-10">
          {/* Title */}
          <div className="text-center mb-8 md:mb-12">
            <div className="flex items-center justify-center mb-4">
              <Image
                src="/icons/mots-mawon.png"
                alt="Mots Mawon"
                width={80}
                height={80}
                className="w-16 h-16 md:w-20 md:h-20"
              />
            </div>
            <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-white mb-4 drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
              <span className="text-madras-yellow">Mots Mawon</span>
            </h1>
            <p className="text-base sm:text-lg text-white drop-shadow-md max-w-2xl mx-auto">
              Retrouve les mots cachés en créole martiniquais ! Sélectionne les lettres avec ta souris pour former les mots.
            </p>
          </div>

          {/* Game Board */}
          {dictData.length > 0 ? (
            <GameBoard dictData={dictData} />
          ) : (
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-8 border border-white/20 shadow-2xl text-center">
              <p className="text-white text-xl">
                Erreur de chargement du dictionnaire. Veuillez réessayer plus tard.
              </p>
            </div>
          )}

          {/* Instructions */}
          <div className="mt-8 bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20 shadow-2xl max-w-3xl mx-auto">
            <h3 className="text-xl font-bold text-madras-yellow mb-4 text-center">
              📖 Comment jouer ?
            </h3>
            <ul className="text-white space-y-2 text-sm md:text-base">
              <li>✅ Clique et maintiens pour sélectionner les lettres</li>
              <li>✅ Les mots peuvent être horizontaux, verticaux ou en diagonale</li>
              <li>✅ Trouve tous les mots pour gagner la partie</li>
              <li>✅ Ton score augmente selon la longueur des mots trouvés</li>
            </ul>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
