'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import Link from 'next/link';

const PlayIcon = () => (
  <svg className="w-5 h-5 md:w-6 md:h-6" viewBox="0 0 24 24" fill="currentColor">
    <path d="M8 5v14l11-7z"/>
  </svg>
);

const ComingSoonIcon = () => (
  <svg className="w-5 h-5 md:w-6 md:h-6" viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" opacity="0.5"/>
    <path d="M12 6v6l4 2"/>
  </svg>
);

export default function Tools() {
  const outils = [
    {
      id: 'koze-kwaze',
      name: 'Kozé Kwazé',
      icon: '/icons/koze-kwaze.png',
      description: 'Traducteur français-créole martiniquais. Apprends et communique en créole !',
      playOnlineUrl: 'http://localhost:8080/#/koze-kwaze',
      playStoreUrl: '#',
      appStoreUrl: '#',
      available: true,
    },
    {
      id: 'met-double',
      name: 'Mét Double',
      icon: '/icons/met-double.png',
      description: 'Application de comptage de points pour le jeu de dominos martiniquais.',
      playOnlineUrl: 'https://kwaze-kreyol.pages.dev/#/met-double',
      playStoreUrl: '#',
      appStoreUrl: '#',
      available: true,
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
            <span className="text-madras-yellow">Nos outils</span>
          </h1>

          <p className="text-base sm:text-lg md:text-xl text-white mb-8 md:mb-12 text-center drop-shadow-md max-w-3xl mx-auto">
            Découvre nos outils créoles ! Utilise-les en ligne ou télécharge les applications sur ton téléphone.
          </p>

          {/* Outils Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8 max-w-4xl mx-auto">
            {outils.map((outil) => {
              const cardClassName = `bg-white/5 backdrop-blur-sm rounded-2xl p-4 border border-white/10 shadow-xl transition-all duration-300 ${outil.playOnlineUrl ? 'cursor-pointer hover:scale-105 hover:bg-white/10 hover:border-madras-yellow/50' : 'cursor-default opacity-75'}`;

              const cardContent = (
                <>
                  {/* Outil Icon - Dominant */}
                  <div className="flex justify-center mb-4">
                    <div className="relative w-full flex justify-center">
                      <div className="absolute inset-0 bg-madras-yellow/20 blur-3xl rounded-full"></div>
                      <Image
                        src={outil.icon}
                        alt={outil.name}
                        width={300}
                        height={300}
                        className="relative w-56 h-56 md:w-64 md:h-64 object-contain drop-shadow-2xl"
                      />
                    </div>
                  </div>

                  {/* Outil Name - Compact */}
                  <h2 className="text-xl md:text-2xl font-bold text-madras-yellow mb-2 text-center">
                    {outil.name}
                  </h2>

                  {/* Outil Description - Compact */}
                  <p className="text-xs md:text-sm text-white/80 mb-4 text-center line-clamp-2">
                    {outil.description}
                  </p>

                  {/* Action Button - Compact */}
                  <div className="mt-auto">
                    {outil.playOnlineUrl ? (
                      <div className="w-full bg-gradient-to-r from-madras-yellow to-madras-orange text-black px-4 py-3 rounded-lg text-sm md:text-base font-bold text-center shadow-lg flex items-center justify-center gap-2 hover:shadow-xl transition-all">
                        <PlayIcon />
                        <span>Utiliser maintenant</span>
                      </div>
                    ) : (
                      <div className="w-full bg-gray-700/50 text-gray-400 px-4 py-3 rounded-lg text-sm md:text-base font-bold text-center cursor-not-allowed border border-gray-600/50 flex items-center justify-center gap-2">
                        <ComingSoonIcon />
                        <span>Bientôt disponible</span>
                      </div>
                    )}
                  </div>
                </>
              );

              return outil.playOnlineUrl ? (
                <Link
                  key={outil.id}
                  href={outil.playOnlineUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={cardClassName}
                >
                  {cardContent}
                </Link>
              ) : (
                <div key={outil.id} className={cardClassName}>
                  {cardContent}
                </div>
              );
            })}
          </div>

          {/* Mobile Apps Section */}
          <div className="mt-16 bg-gradient-to-br from-white/15 to-white/5 backdrop-blur-md rounded-3xl p-8 md:p-12 border border-white/20 shadow-2xl max-w-4xl mx-auto">
            <div className="text-center mb-8">
              <h3 className="text-3xl md:text-4xl font-bold text-madras-yellow mb-4">
                Bientôt sur mobile
              </h3>
              <p className="text-base md:text-lg text-white/90 max-w-2xl mx-auto leading-relaxed">
                Nos outils seront prochainement disponibles sur iOS et Android.
                Télécharge les applications gratuites et utilise-les hors ligne !
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-6">
              <a
                href="#"
                className="opacity-60 cursor-not-allowed"
                onClick={(e) => e.preventDefault()}
              >
                <Image
                  src="/icons/app-store-badge.svg"
                  alt="Télécharger sur l'App Store"
                  width={160}
                  height={48}
                  className="h-14 w-auto"
                />
              </a>
              <a
                href="#"
                className="opacity-60 cursor-not-allowed"
                onClick={(e) => e.preventDefault()}
              >
                <Image
                  src="/icons/google-play-badge.webp"
                  alt="Disponible sur Google Play"
                  width={180}
                  height={53}
                  className="h-14 w-auto"
                />
              </a>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
