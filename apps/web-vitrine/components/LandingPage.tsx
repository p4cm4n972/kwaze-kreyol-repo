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
  subtitle: 'La plateforme interactive de la langue et de la culture martiniquaise.',
  presentation: (
    <>
      Valoriser la{' '}
      <strong className="font-bold text-madras-yellow">
        langue créole martiniquaise
      </strong>{' '}
      à travers le numérique. Que ce soit pour apprendre, jouer ou échanger,
      notre mission est de mettre le créole au cœur du digital, avec{' '}
      <strong className="font-bold text-madras-red">
        respect, fierté et modernité
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
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-12 items-center max-w-6xl mx-auto px-4 py-8 md:p-8">
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
            <div className="relative p-6 md:p-8 bg-white/10 backdrop-blur-md rounded-2xl shadow-2xl border border-white/20 w-full max-w-sm md:max-w-full">
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
                        className="relative w-28 h-28 sm:w-32 sm:h-32 md:w-40 md:h-40 bg-white/20 backdrop-blur-sm rounded-full hover:bg-white/30 transition-all duration-300 hover:scale-105 cursor-pointer shadow-lg overflow-hidden flex items-center justify-center"
                      >
                        <Image
                          src={icon.src}
                          alt={icon.alt}
                          width={140}
                          height={140}
                          className="w-20 h-20 sm:w-24 sm:h-24 md:w-32 md:h-32 object-cover rounded-full"
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
                  <button
                    ref={(el) => {
                      buttonsRefs.current[index] = el;
                    }}
                    className="mt-4 px-6 py-3 bg-madras-yellow text-black font-bold rounded-lg text-sm md:text-base"
                  >
                    En savoir plus
                  </button>
                </div>
              </div>
            </div>
          </section>
        );
      })}
      </div>
      <Footer />
    </>
  );
};

export default LandingPage;
