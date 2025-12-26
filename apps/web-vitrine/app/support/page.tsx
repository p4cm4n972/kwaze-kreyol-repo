'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import Link from 'next/link';

export default function Support() {
  return (
    <>
      <Navbar />
      <section
        className="min-h-screen w-full bg-cover bg-center py-20 md:py-32 px-4 flex items-center justify-center relative bg-responsive"
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

        <div className="max-w-6xl mx-auto relative z-10 w-full">
          {/* Title */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-8 md:mb-12 text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Support utilisateur</span>
          </h1>

          <p className="text-base sm:text-lg md:text-xl text-white mb-8 md:mb-12 text-center drop-shadow-md">
            Besoin d'aide ? Notre équipe est là pour vous assister dans votre expérience avec Kwazé Kréyol.
          </p>

          {/* Support Options Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8 max-w-4xl mx-auto">
            {/* FAQ Box */}
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl flex flex-col justify-between">
              <div>
                <h2 className="text-2xl sm:text-3xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
                  FAQ
                </h2>
                <p className="text-sm sm:text-base md:text-lg text-white mb-6 md:mb-8 drop-shadow-md">
                  Consultez notre FAQ pour trouver des réponses rapides à vos questions.
                </p>
              </div>
              <Link
                href="/support/faq"
                className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-base md:text-lg font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg text-center"
              >
                Voir la FAQ
              </Link>
            </div>

            {/* Contact Box */}
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl flex flex-col justify-between">
              <div>
                <h2 className="text-2xl sm:text-3xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
                  Nous contacter
                </h2>
                <p className="text-sm sm:text-base md:text-lg text-white mb-6 md:mb-8 drop-shadow-md">
                  Un problème technique ou une suggestion ? Écrivez-nous !
                </p>
              </div>
              <a
                href="mailto:contact@itmade.fr"
                className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-base md:text-lg font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg text-center"
              >
                contact@itmade.fr
              </a>
            </div>
          </div>

          {/* Additional Info */}
          <div className="mt-8 md:mt-12 max-w-3xl mx-auto">
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl">
              <h3 className="text-xl md:text-2xl font-bold text-white mb-4 text-center">
                Informations utiles
              </h3>
              <ul className="space-y-3 text-white/90 text-sm sm:text-base md:text-lg">
                <li className="flex items-start">
                  <span className="text-madras-yellow mr-3 text-xl">•</span>
                  <span>Temps de réponse moyen : 24-48h</span>
                </li>
                <li className="flex items-start">
                  <span className="text-madras-yellow mr-3 text-xl">•</span>
                  <span>Disponible du lundi au vendredi</span>
                </li>
                <li className="flex items-start">
                  <span className="text-madras-yellow mr-3 text-xl">•</span>
                  <span>Support en français et en créole</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
