'use client';
import { useRef } from 'react';
import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';
import Image from 'next/image';
import LogoMorph from './animations/LogoMorph';
import DorlisMorph from './animations/DorlisMorph';
import TranslatorMorph from './animations/TranslatorMorph';
import DominoMorph from './animations/DominoMorph';
import Navbar from './Navbar';
import Footer from './Footer';

const heroData = {
  id: 'hero',
  logo: '/images/logo-kk.webp',
  title: 'Kwazé Kréyol',
  subtitle: 'Apprendre, jouer, partager… en créole martiniquais.',
  presentation: (
   <>
   La
  rencontre entre tradition et innovation. <br />
  Le{' '}
  <strong className="font-bold text-madras-yellow">
    créole martiniquais
  </strong>{' '}
  y vit, s’apprend, se joue et se partage, avec{' '}
  <strong className="font-bold text-madras-red">
    fierté, respect et modernité
  </strong>
  .
</>

  ),
};

const pillarsData = [
  {
    id: 'section1',
    title: 'Jé Mo Kréyol',
    text: 'Défiez vos amis et enrichissez votre vocabulaire avec nos jeux de mots 100% créole.',
    morphComponent: LogoMorph,
    bgColor: '#FFD700', // Jaune bouton d'or
    icons: [
      { src: '/icons/mots-mawon.png', alt: 'Mots Mawon' },
      { src: '/icons/skrabb.png', alt: 'Skrabb' },
    ],
  },
  {
    id: 'section2',
    title: 'Jé ba piti ek gran',
    text: "Plongez dans l'univers mystique du Dorlis (RPG inspiré du Loup-Garou) ou redécouvrez les Dominos aux règles de la Martinique.",
    morphComponent: DorlisMorph,
    bgColor: '#FF0000', // Rouge vif
    icons: [
      { src: '/icons/endorlisseur.png', alt: 'Endorlisseur' },
      { src: '/icons/double-siz.png', alt: 'Double Siz' },
    ],
  },
  {
    id: 'section3',
    title: 'Tradiktè',
    text: 'Passez du français au créole martiniquais grâce à notre dictionnaire enrichi par Raphaël Confiant.',
    morphComponent: TranslatorMorph,
    bgColor: '#D2691E', // Orange terreux
    icons: [
      { src: '/icons/koze-kwaze.png', alt: 'Koze Kwaze' },
    ],
  },
  {
    id: 'section4',
    title: 'Zouti',
    text: 'Notez vos scores, analysez vos statistiques et rejoignez le classement virtuel des meilleurs joueurs.',
    morphComponent: DominoMorph,
    bgColor: '#006400', // Vert forêt
    icons: [
      { src: '/icons/met-double.png', alt: 'Met Double' },
    ],
  },
];

const LandingPage = () => {
  const container = useRef(null);
  const heroSectionRef = useRef(null);
  const heroLogoRef = useRef(null);
  const heroTextRef = useRef<HTMLDivElement>(null);
  const sectionsRefs = useRef<(HTMLElement | null)[]>([]);
  const buttonsRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const morphRefs = useRef<(SVGElement | null)[]>([]);
  const morphContainerRefs = useRef<(HTMLDivElement | null)[]>([]);

  useGSAP(
    () => {
      gsap.registerPlugin(ScrollTrigger, MorphSVGPlugin);

      // Animation d'entrée pour le logo
      gsap.from(heroLogoRef.current, {
        scale: 0.5,
        opacity: 0,
        duration: 1.8,
        ease: 'elastic.out(1, 0.5)',
        delay: 0.3,
      });

      // Hero Parallax
      gsap.to(heroSectionRef.current, {
        backgroundPosition: '50% 100%',
        ease: 'none',
        scrollTrigger: {
          trigger: heroSectionRef.current,
          start: 'top top',
          end: 'bottom top',
          scrub: true,
        },
      });

      const cleanups: (() => void)[] = [];

      pillarsData.forEach((data, index) => {
        const section = sectionsRefs.current[index];
        const button = buttonsRefs.current[index];
        const morphTarget = morphRefs.current[index];
        const morphContainer = morphContainerRefs.current[index];

        if (button && section) {
          // Button hover animation
          const buttonTween = gsap.to(button, {
            scale: 1.1,
            paused: true,
            duration: 0.3,
            ease: 'elastic.out(1, 0.3)',
          });

          const playTween = () => buttonTween.play();
          const reverseTween = () => buttonTween.reverse();

          button.addEventListener('mouseenter', playTween);
          button.addEventListener('mouseleave', reverseTween);

          // SVG Morphing hover animation
          if (morphTarget && morphContainer) {
            const morphTween = gsap.to(morphTarget, {
              morphSVG: `.morph-${data.id}-end`,
              duration: 1.2,
              ease: 'power2.inOut',
              paused: true,
            });

            const playMorph = () => morphTween.play();
            const reverseMorph = () => morphTween.reverse();

            morphContainer.addEventListener('mouseenter', playMorph);
            morphContainer.addEventListener('mouseleave', reverseMorph);

            cleanups.push(() => {
              morphContainer.removeEventListener('mouseenter', playMorph);
              morphContainer.removeEventListener('mouseleave', reverseMorph);
            });
          }

          cleanups.push(() => {
            button.removeEventListener('mouseenter', playTween);
            button.removeEventListener('mouseleave', reverseTween);
          });
        }
      });

      return () => {
        cleanups.forEach((cleanup) => cleanup());
      };
    },
    { scope: container, dependencies: [] },
  );

  return (
    <>
      <Navbar />
      <div ref={container}>
        {/* Hero Section */}
        <section
          id="hero"
          ref={heroSectionRef}
          className="h-screen w-full bg-cover bg-center flex items-center justify-center bg-responsive"
        >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-12 items-center max-w-6xl mx-auto px-4 pt-24 pb-8 md:p-8">
          {/* Colonne de gauche : Texte de présentation */}
          <div
            ref={heroTextRef}
            className="text-white text-center md:text-left order-2 md:order-1"
          >
            <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold mb-4 drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">{heroData.title}</h1>
            <h2 className="text-xl sm:text-2xl md:text-3xl mb-6 text-madras-yellow drop-shadow-[0_2px_8px_rgba(0,0,0,0.8)]">{heroData.subtitle}</h2>
            <p className="text-base sm:text-lg md:text-xl leading-relaxed drop-shadow-[0_2px_6px_rgba(0,0,0,0.6)] bg-gradient-to-r from-black/30 to-transparent p-3 md:p-4 rounded-lg backdrop-blur-[2px]">{heroData.presentation}</p>
          </div>

          {/* Colonne de droite : Logo */}
          <div ref={heroLogoRef} className="flex justify-center order-1 md:order-2">
            <div className="relative p-3 md:p-8 bg-white/10 backdrop-blur-md rounded-2xl shadow-2xl border border-white/20 w-full max-w-xs md:max-w-full">
              <Image
                src={heroData.logo}
                alt="Kwazé Kréyol Logo"
                width={512}
                height={512}
                className="w-full h-auto"
                style={{
                  filter: 'drop-shadow(0 10px 30px rgba(0, 0, 0, 0.5)) drop-shadow(0 0 40px rgba(255, 215, 0, 0.4)) drop-shadow(0 0 80px rgba(255, 215, 0, 0.2))',
                }}
              />
            </div>
          </div>
        </div>
      </section>

      {/* Pillars Sections */}
      {pillarsData.map((data, index) => {
        const MorphComponent = data.morphComponent;
        return (
          <section
            key={data.id}
            ref={(el) => {
              sectionsRefs.current[index] = el;
            }}
            className="h-screen w-full flex items-center justify-center"
            style={{ backgroundColor: data.bgColor }}
          >
            <div className="flex flex-col md:flex-row items-center justify-center w-full max-w-4xl gap-8 px-4">
              <div className="w-full md:w-1/2 flex flex-col items-center gap-6 md:gap-8">
                {data.icons && (
                  <div className="flex gap-4 md:gap-8 w-full justify-center">
                    {data.icons.map((icon, iconIndex) => (
                      <div
                        key={iconIndex}
                        className="relative w-40 h-40 sm:w-48 sm:h-48 md:w-56 md:h-56 bg-white/20 backdrop-blur-sm rounded-full hover:bg-white/30 transition-all duration-300 hover:scale-105 cursor-pointer shadow-lg overflow-hidden flex items-center justify-center"
                      >
                        <Image
                          src={icon.src}
                          alt={icon.alt}
                          width={224}
                          height={224}
                          className="w-32 h-32 sm:w-40 sm:h-40 md:w-48 md:h-48 object-cover rounded-full"
                        />
                      </div>
                    ))}
                  </div>
                )}

                <div
                  ref={(el) => {
                    morphContainerRefs.current[index] = el;
                  }}
                  className="cursor-pointer w-full max-w-xs md:max-w-full"
                >
                  <MorphComponent
                    ref={(el) => {
                      morphRefs.current[index] = el;
                    }}
                    startClass={`morph-${data.id}`}
                    endClass={`morph-${data.id}-end`}
                  />
                </div>
              </div>

              <div className="w-full md:w-1/2 p-6 md:p-8 bg-white/30 backdrop-blur-sm rounded-lg">
                <h2 className="text-3xl md:text-4xl font-bold text-white mb-4 text-center md:text-left">
                  {data.title}
                </h2>
                <p className="text-white mb-6 text-base md:text-lg text-center md:text-left">{data.text}</p>

                <div className="flex justify-center md:justify-start">
                  <a
                    href="https://jé.kwazé-kréyol.fr"
                    target="_blank"
                    rel="noopener noreferrer"
                    ref={(el) => {
                      buttonsRefs.current[index] = el as unknown as HTMLButtonElement;
                    }}
                    className="mt-4 px-6 py-3 bg-madras-yellow text-black font-bold rounded-lg text-sm md:text-base hover:bg-yellow-400 transition-colors"
                  >
                    Jouer maintenant
                  </a>
                </div>
              </div>
            </div>
          </section>
        );
      })}

      {/* Mobile Apps Section */}
      <section className="w-full py-20 md:py-32 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center">
        <div className="max-w-4xl mx-auto px-4">
          <div className="bg-gradient-to-br from-madras-yellow/10 to-madras-orange/10 backdrop-blur-md rounded-3xl p-8 md:p-12 border border-madras-yellow/30 shadow-2xl">
            <div className="text-center mb-8">
              <h3 className="text-3xl md:text-4xl font-bold text-madras-yellow mb-4 drop-shadow-lg">
                Bientôt sur mobile
              </h3>
              <p className="text-base md:text-lg text-white max-w-2xl mx-auto leading-relaxed drop-shadow-md">
                Nos jeux seront prochainement disponibles sur iOS et Android.
                Télécharge les applications gratuites et joue hors ligne !
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
      </div>
      <Footer />
    </>
  );
};

export default LandingPage;
