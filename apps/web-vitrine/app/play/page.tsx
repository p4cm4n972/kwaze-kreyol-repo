'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import Link from 'next/link';

export default function Play() {
  const games = [
    {
      id: 'mots-mawon',
      name: 'Mots Mawon',
      icon: '/icons/mots-mawon.png',
      description: 'Jeu de mots cachés en créole martiniquais. Retrouve les mots dissimulés dans la grille !',
      playOnlineUrl: null, // Bientôt disponible en Flutter
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
    {
      id: 'skrabb',
      name: 'Skrabb',
      icon: '/icons/skrabb.png',
      description: 'Scrabble créole ! Forme des mots en créole et marque un maximum de points.',
      playOnlineUrl: null,
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
    {
      id: 'endorlisseur',
      name: 'Endorlisseur',
      icon: '/icons/endorlisseur.png',
      description: 'Jeu de stratégie inspiré de la culture créole martiniquaise.',
      playOnlineUrl: null,
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
    {
      id: 'double-siz',
      name: 'Double Siz',
      icon: '/icons/double-siz.png',
      description: 'Jeu de dominos aux règles martiniquaises. Affronte tes adversaires !',
      playOnlineUrl: null,
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
    {
      id: 'koze-kwaze',
      name: 'Kozé Kwazé',
      icon: '/icons/koze-kwaze.png',
      description: 'Jeu de questions-réponses sur la culture créole martiniquaise.',
      playOnlineUrl: null,
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
    {
      id: 'met-double',
      name: 'Mét Double',
      icon: '/icons/met-double.png',
      description: 'Jeu de cartes traditionnel martiniquais. Stratégie et réflexion !',
      playOnlineUrl: null,
      playStoreUrl: '#', // À compléter
      appStoreUrl: '#', // À compléter
      available: false,
    },
  ];

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
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 md:mb-8 text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Nos jeux</span>
          </h1>

          <p className="text-base sm:text-lg md:text-xl text-white mb-8 md:mb-12 text-center drop-shadow-md max-w-3xl mx-auto">
            Découvre nos jeux 100% créole ! Joue en ligne ou télécharge les applications sur ton téléphone.
          </p>

          {/* Games Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
            {games.map((game) => (
              <div
                key={game.id}
                className="bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20 shadow-2xl hover:scale-105 transition-transform duration-300"
              >
                {/* Game Icon */}
                <div className="flex justify-center mb-4">
                  <div className="w-24 h-24 md:w-32 md:h-32 rounded-full bg-white/20 flex items-center justify-center">
                    <Image
                      src={game.icon}
                      alt={game.name}
                      width={80}
                      height={80}
                      className="w-16 h-16 md:w-20 md:h-20 object-contain"
                    />
                  </div>
                </div>

                {/* Game Name */}
                <h2 className="text-xl md:text-2xl font-bold text-madras-yellow mb-3 text-center">
                  {game.name}
                </h2>

                {/* Game Description */}
                <p className="text-sm md:text-base text-white mb-6 text-center">
                  {game.description}
                </p>

                {/* Action Buttons */}
                <div className="space-y-3">
                  {/* Play Online Button */}
                  {game.playOnlineUrl ? (
                    <Link
                      href={game.playOnlineUrl}
                      className="block w-full bg-madras-yellow text-black px-4 py-3 rounded-lg text-sm md:text-base font-bold hover:bg-madras-orange transition-all duration-300 text-center"
                    >
                      🎮 Jouer en ligne
                    </Link>
                  ) : (
                    <div className="w-full bg-gray-600 text-gray-300 px-4 py-3 rounded-lg text-sm md:text-base font-bold text-center cursor-not-allowed">
                      🎮 Bientôt disponible
                    </div>
                  )}

                  {/* Download Buttons */}
                  <div className="grid grid-cols-2 gap-2">
                    <a
                      href={game.playStoreUrl}
                      className={`flex items-center justify-center px-3 py-2 rounded-lg text-xs md:text-sm font-semibold transition-all duration-300 ${
                        game.available
                          ? 'bg-madras-green text-white hover:bg-green-700'
                          : 'bg-gray-600 text-gray-300 cursor-not-allowed'
                      }`}
                      onClick={(e) => !game.available && e.preventDefault()}
                    >
                      <span>📱 Play Store</span>
                    </a>
                    <a
                      href={game.appStoreUrl}
                      className={`flex items-center justify-center px-3 py-2 rounded-lg text-xs md:text-sm font-semibold transition-all duration-300 ${
                        game.available
                          ? 'bg-madras-green text-white hover:bg-green-700'
                          : 'bg-gray-600 text-gray-300 cursor-not-allowed'
                      }`}
                      onClick={(e) => !game.available && e.preventDefault()}
                    >
                      <span>🍎 App Store</span>
                    </a>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Info Section */}
          <div className="mt-12 bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl max-w-3xl mx-auto">
            <h3 className="text-xl md:text-2xl font-bold text-madras-yellow mb-4 text-center">
              📲 Télécharge nos applications
            </h3>
            <p className="text-sm md:text-base text-white text-center">
              Toutes nos applications sont gratuites et disponibles sur Android et iOS.
              Joue hors ligne et emporte le créole partout avec toi !
            </p>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
