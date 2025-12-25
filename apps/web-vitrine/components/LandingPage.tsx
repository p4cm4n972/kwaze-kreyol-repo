'use client';
import React, { useRef } from 'react';
import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import LogoMorph from './animations/LogoMorph';
import DorlisMorph from './animations/DorlisMorph';
import TranslatorMorph from './animations/TranslatorMorph';
import DominoMorph from './animations/DominoMorph';

gsap.registerPlugin(ScrollTrigger);

const sectionsData = [
  {
    id: 'section1',
    title: 'Jé Mo Kréyol',
    text: 'Défiez vos amis et enrichissez votre vocabulaire avec nos jeux de mots 100% créole.',
    morphComponent: LogoMorph,
  },
  {
    id: 'section2',
    title: 'Jeux de Famille',
    text: "Plongez dans l'univers mystique du Dorlis (RPG inspiré du Loup-Garou) ou redécouvrez les Dominos aux règles de la Martinique.",
    morphComponent: DorlisMorph,
  },
  {
    id: 'section3',
    title: 'Traducteur Intelligent',
    text: 'Passez du français au créole martiniquais grâce à notre dictionnaire enrichi par Raphaël Confiant.',
    morphComponent: TranslatorMorph,
  },
  {
    id: 'section4',
    title: 'Dominos Mentor',
    text: 'Notez vos scores, analysez vos statistiques et rejoignez le classement virtuel des meilleurs joueurs.',
    morphComponent: DominoMorph,
  },
];

const LandingPage = () => {
  const container = useRef(null);
  const sectionsRefs = useRef([]);
  const buttonsRefs = useRef([]);

  useGSAP(
    () => {
      const cleanups = [];

      sectionsData.forEach((data, index) => {
        const section = sectionsRefs.current[index];
        const button = buttonsRefs.current[index];

        // Parallax
        gsap.to(section, {
          backgroundPosition: '50% 100%',
          ease: 'none',
          scrollTrigger: {
            trigger: section,
            start: 'top top',
            end: 'bottom top',
            scrub: true,
          },
        });

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

        // Morphing animation
        gsap.to(`.morph-${data.id} path`, {
          morphSVG: `.morph-${data.id}-end path`,
          duration: 1,
          ease: 'power1.inOut',
          scrollTrigger: {
            trigger: section,
            start: 'top top',
            end: 'bottom top',
            scrub: true,
          },
        });

        cleanups.push(() => {
          button.removeEventListener('mouseenter', playTween);
          button.removeEventListener('mouseleave', reverseTween);
        });
      });

      return () => {
        cleanups.forEach((cleanup) => cleanup());
      };
    },
    { scope: container, dependencies: [] },
  );

  return (
    <div ref={container}>
      {sectionsData.map((data, index) => {
        const MorphComponent = data.morphComponent;
        return (
          <section
            key={data.id}
            ref={(el) => (sectionsRefs.current[index] = el)}
            className="h-screen w-full bg-cover bg-center flex items-center justify-center"
            style={{ backgroundImage: "url('/images/bkg.webp')" }}
          >
            <div className="flex items-center justify-center w-full max-w-4xl">
              <div className="w-1/2">
                <MorphComponent
                  startClass={`morph-${data.id}`}
                  endClass={`morph-${data.id}-end`}
                />
              </div>
              <div className="w-1/2 p-8 bg-white/30 backdrop-blur-sm rounded-lg">
                <h2 className="text-4xl font-bold text-white mb-4">
                  {data.title}
                </h2>
                <p className="text-white">{data.text}</p>
                <button
                  ref={(el) => (buttonsRefs.current[index] = el)}
                  className="mt-4 px-6 py-2 bg-madras-yellow text-black font-bold rounded-lg"
                >
                  En savoir plus
                </button>
              </div>
            </div>
          </section>
        );
      })}
    </div>
  );
};

export default LandingPage;
