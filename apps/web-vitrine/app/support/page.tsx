'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import { useState } from 'react';

export default function Support() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const faqs = [
    {
      question: "Est-ce que Kwazé Kréyol fonctionne hors ligne ?",
      answer: "Oui, une fois l'application téléchargée, certaines fonctionnalités seront disponibles hors ligne, comme les jeux ou l'accès à une partie du dictionnaire."
    },
    {
      question: "Où puis-je télécharger les applications ?",
      answer: "Tu peux les retrouver sur le Google Play Store et l'App Store. Si elles ne sont pas encore disponibles, cela signifie qu'elles sont encore en cours de validation."
    },
    {
      question: "Est-ce que l'appli est gratuite ?",
      answer: "Oui, toutes les applications sont gratuites. Certaines fonctionnalités premium pourraient arriver plus tard, mais les jeux et la traduction resteront accessibles."
    },
    {
      question: "Est-ce que je peux suggérer un mot ou une amélioration ?",
      answer: "Oui, tu peux proposer des idées en nous contactant par email. On lit tous les messages."
    }
  ];

  const toggleFaq = (index: number) => {
    setOpenFaq(openFaq === index ? null : index);
  };

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
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 md:gap-8">
            {/* FAQ Section */}
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl">
              <h2 className="text-2xl sm:text-3xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
                Foire aux questions (FAQ)
              </h2>
              <p className="text-sm sm:text-base text-white mb-6 drop-shadow-md">
                Tu as une question ? Voici les réponses aux interrogations les plus fréquentes.
              </p>

              <div className="space-y-4">
                {faqs.map((faq, index) => (
                  <div
                    key={index}
                    className="bg-white/5 rounded-lg border border-white/10 overflow-hidden transition-all duration-300"
                  >
                    <button
                      onClick={() => toggleFaq(index)}
                      className="w-full text-left p-4 flex items-center justify-between hover:bg-white/10 transition-colors duration-200"
                    >
                      <span className="text-white font-semibold text-sm sm:text-base pr-4">
                        {faq.question}
                      </span>
                      <svg
                        className={`w-5 h-5 text-madras-yellow transition-transform duration-300 flex-shrink-0 ${
                          openFaq === index ? 'rotate-180' : ''
                        }`}
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M19 9l-7 7-7-7"
                        />
                      </svg>
                    </button>
                    <div
                      className={`transition-all duration-300 ease-in-out ${
                        openFaq === index
                          ? 'max-h-96 opacity-100'
                          : 'max-h-0 opacity-0'
                      } overflow-hidden`}
                    >
                      <div className="p-4 pt-0 text-white/90 text-sm sm:text-base">
                        {faq.answer}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <p className="text-sm text-white/80 mt-6 text-center">
                Tu ne trouves pas ta réponse ? Contacte-nous !
              </p>
            </div>

            {/* Contact Section */}
            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 border border-white/20 shadow-2xl flex flex-col justify-center">
              <h2 className="text-2xl sm:text-3xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
                Nous contacter
              </h2>
              <p className="text-sm sm:text-base md:text-lg text-white mb-6 md:mb-8 drop-shadow-md">
                Un problème technique ou une suggestion ? Écrivez-nous !
              </p>
              <a
                href="mailto:contact@itmade.fr"
                className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-lg md:text-xl font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg text-center"
              >
                contact@itmade.fr
              </a>

              <div className="mt-8 pt-8 border-t border-white/20">
                <h3 className="text-xl font-bold text-white mb-4">
                  Informations utiles
                </h3>
                <ul className="space-y-3 text-white/90 text-sm sm:text-base">
                  <li className="flex items-start">
                    <span className="text-madras-yellow mr-2">•</span>
                    <span>Temps de réponse moyen : 24-48h</span>
                  </li>
                  <li className="flex items-start">
                    <span className="text-madras-yellow mr-2">•</span>
                    <span>Disponible du lundi au vendredi</span>
                  </li>
                  <li className="flex items-start">
                    <span className="text-madras-yellow mr-2">•</span>
                    <span>Support en français et en créole</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
