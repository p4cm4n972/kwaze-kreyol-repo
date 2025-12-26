import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Support",
  description: "Besoin d'aide avec Kwazé Kréyol ? Contactez notre équipe pour toute question ou suggestion concernant nos jeux et outils créoles.",
  openGraph: {
    title: "Support - Kwazé Kréyol",
    description: "Contactez-nous pour toute question ou suggestion.",
    url: "https://kwaze-kreyol.com/support",
  },
};

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

        <div className="max-w-5xl mx-auto text-center relative z-10">
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-8 md:mb-12 drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Support</span>
          </h1>
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 border border-white/20 shadow-2xl">
            <h2 className="text-2xl sm:text-3xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
              Besoin d'aide ?
            </h2>
            <p className="text-base sm:text-lg md:text-xl text-white mb-6 md:mb-8 drop-shadow-md">
              Notre équipe est là pour vous accompagner. N'hésitez pas à nous contacter pour toute question ou suggestion.
            </p>
            <a
              href="mailto:contact@itmade.fr"
              className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-lg md:text-xl font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg"
            >
              contact@itmade.fr
            </a>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
