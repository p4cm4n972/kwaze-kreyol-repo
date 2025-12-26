'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import Link from 'next/link';
import { useState } from 'react';

export default function FAQ() {
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

        <div className="max-w-4xl mx-auto relative z-10 w-full">
          {/* Title */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 md:mb-8 text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Foire aux questions (FAQ)</span>
          </h1>

          <p className="text-base sm:text-lg md:text-xl text-white mb-8 md:mb-12 text-center drop-shadow-md">
            Tu as une question ? Voici les réponses aux interrogations les plus fréquentes.
          </p>

          {/* FAQ Section */}
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-10 border border-white/20 shadow-2xl">
            <div className="space-y-4">
              {faqs.map((faq, index) => (
                <div
                  key={index}
                  className="bg-white/5 rounded-lg border border-white/10 overflow-hidden transition-all duration-300"
                >
                  <button
                    onClick={() => toggleFaq(index)}
                    className="w-full text-left p-4 md:p-5 flex items-center justify-between hover:bg-white/10 transition-colors duration-200"
                  >
                    <span className="text-white font-semibold text-sm sm:text-base md:text-lg pr-4">
                      {faq.question}
                    </span>
                    <svg
                      className={`w-5 h-5 md:w-6 md:h-6 text-madras-yellow transition-transform duration-300 flex-shrink-0 ${
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
                    <div className="p-4 md:p-5 pt-0 text-white/90 text-sm sm:text-base md:text-lg">
                      {faq.answer}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-8 pt-8 border-t border-white/20 text-center">
              <p className="text-base md:text-lg text-white mb-4">
                Tu ne trouves pas ta réponse ?
              </p>
              <Link
                href="/support"
                className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-base md:text-lg font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg"
              >
                Contacte-nous ici
              </Link>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
