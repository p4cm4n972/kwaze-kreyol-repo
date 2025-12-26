'use client';
import Image from 'next/image';

const AboutPage = () => {
  return (
    <section
      id="about"
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

      <div className="max-w-5xl mx-auto relative z-10">
        {/* En-tête */}
        <div className="text-center mb-8 md:mb-16">
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            À propos de{' '}
            <span className="text-madras-yellow">Kwazé Kréyol</span>
          </h1>
        </div>

        {/* Mission */}
        <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 mb-6 md:mb-8 border border-white/20 shadow-2xl">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">Notre Mission</h2>
          <p className="text-base sm:text-lg md:text-xl text-white leading-relaxed drop-shadow-md">
            Kwazé Kréyol est une initiative culturelle et technologique qui vise
            à <strong className="text-madras-yellow">valoriser la langue créole martiniquaise</strong> à
            travers des outils numériques modernes. Que ce soit pour apprendre,
            jouer ou échanger, notre mission est de mettre le créole au cœur du
            numérique, avec{' '}
            <strong className="text-madras-red">
              respect, fierté et modernité
            </strong>
            .
          </p>
        </div>

        {/* Histoire */}
        <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 mb-6 md:mb-8 border border-white/20 shadow-2xl">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-madras-red mb-4 md:mb-6 drop-shadow-lg">Notre Histoire</h2>
          <p className="text-base sm:text-lg md:text-xl text-white leading-relaxed mb-4 drop-shadow-md">
            Le créole martiniquais est une langue vivante, riche d'histoire et
            d'émotion. Pourtant, peu d'outils modernes permettent de le
            pratiquer ou de le transmettre dans un environnement numérique.
          </p>
          <p className="text-base sm:text-lg md:text-xl text-white leading-relaxed drop-shadow-md">
            <strong className="text-madras-yellow">Kwazé Kréyol</strong> est né
            de cette volonté : croiser le créole avec le digital, pour proposer
            des applications de traduction, des jeux de lettres captivants, et
            même un jeu de dominos à la sauce martiniquaise !
          </p>
        </div>

        {/* L'équipe */}
        <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 mb-6 md:mb-8 border border-white/20 shadow-2xl">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-madras-orange mb-4 md:mb-6 drop-shadow-lg">L'Équipe</h2>
          <p className="text-base sm:text-lg md:text-xl text-white leading-relaxed mb-4 drop-shadow-md">
            Ce projet est conçu et développé par{' '}
            <strong className="text-madras-yellow">ITMade</strong>, une agence
            indépendante fondée par un développeur martiniquais passionné par :
          </p>
          <ul className="space-y-3 text-white">
            <li className="flex items-start gap-3">
              <span className="text-madras-yellow text-2xl font-bold">→</span>
              <span className="text-base sm:text-lg md:text-xl drop-shadow-md">La transmission des savoirs</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-madras-yellow text-2xl font-bold">→</span>
              <span className="text-base sm:text-lg md:text-xl drop-shadow-md">Les outils open source</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-madras-yellow text-2xl font-bold">→</span>
              <span className="text-base sm:text-lg md:text-xl drop-shadow-md">L'innovation numérique locale</span>
            </li>
          </ul>
        </div>

        {/* Contact */}
        <div className="bg-white/20 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 shadow-2xl border border-white/30">
          <div className="text-center">
            <h2 className="text-2xl sm:text-3xl md:text-4xl font-bold text-madras-yellow mb-4 md:mb-6 drop-shadow-lg">
              Envie de collaborer ?
            </h2>
            <p className="text-base sm:text-lg md:text-xl text-white mb-6 md:mb-8 drop-shadow-md">
              Pour en savoir plus, collaborer ou soutenir le projet, vous pouvez
              nous écrire à :
            </p>
            <a
              href="mailto:contact@itmade.fr"
              className="inline-block bg-madras-yellow text-black px-6 md:px-8 py-3 md:py-4 rounded-lg text-lg md:text-xl font-bold hover:bg-madras-orange transition-all duration-300 hover:scale-105 shadow-lg"
            >
              contact@itmade.fr
            </a>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AboutPage;
