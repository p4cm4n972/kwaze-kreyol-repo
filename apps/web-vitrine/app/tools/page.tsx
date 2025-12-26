import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Outils",
  description: "Dictionnaire créole-français, traducteur enrichi par Raphaël Confiant, statistiques de jeux et outils pour pratiquer et apprendre le créole martiniquais.",
  openGraph: {
    title: "Outils créoles - Kwazé Kréyol",
    description: "Dictionnaire, traducteur et outils pour apprendre le créole martiniquais.",
    url: "https://kwaze-kreyol.com/tools",
  },
};

export default function Tools() {
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
            <span className="text-madras-yellow">Outils</span>
          </h1>
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 border border-white/20 shadow-2xl">
            <p className="text-2xl sm:text-3xl text-white font-bold mb-6 md:mb-8 drop-shadow-lg">
              Nos outils créoles arrivent bientôt !
            </p>
            <p className="text-base sm:text-lg md:text-xl text-white drop-shadow-md">
              Dictionnaire, traducteur, statistiques de jeux et bien plus encore...
            </p>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
