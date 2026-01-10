'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';

export default function Traduction() {
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

        <div className="max-w-4xl mx-auto relative z-10">
          {/* Title */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 md:mb-8 text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Traducteur Créole</span>
          </h1>

          <p className="text-base sm:text-lg md:text-xl text-white mb-8 md:mb-12 text-center drop-shadow-md max-w-3xl mx-auto">
            Traduis du français vers le créole martiniquais et vice-versa. Apprends et communique en créole !
          </p>

          {/* Traducteur intégré via iframe */}
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20 shadow-xl">
            <div className="relative w-full" style={{ paddingBottom: '75%', minHeight: '500px' }}>
              <iframe
                src="https://jé.kwazé-kréyol.fr/#/koze-kwaze"
                className="absolute inset-0 w-full h-full rounded-xl"
                style={{ border: 'none', minHeight: '500px' }}
                title="Traducteur Kozé Kwazé"
                allow="clipboard-write"
              />
            </div>
          </div>

          {/* Info Section */}
          <div className="mt-12 bg-gradient-to-br from-white/15 to-white/5 backdrop-blur-md rounded-3xl p-8 md:p-12 border border-white/20 shadow-2xl">
            <div className="text-center">
              <h3 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                Kozé Kwazé
              </h3>
              <p className="text-base md:text-lg text-white/90 max-w-2xl mx-auto leading-relaxed mb-6">
                Notre traducteur utilise une base de données de plus de 5000 mots et expressions créoles martiniquaises.
                Parfait pour apprendre le créole ou communiquer avec des locuteurs natifs !
              </p>
              <a
                href="https://jé.kwazé-kréyol.fr/#/koze-kwaze"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 bg-gradient-to-r from-madras-yellow to-madras-orange text-black px-6 py-3 rounded-lg font-bold hover:shadow-xl transition-all hover:scale-105"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/>
                </svg>
                Ouvrir en plein écran
              </a>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
