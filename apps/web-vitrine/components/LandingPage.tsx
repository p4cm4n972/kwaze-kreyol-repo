'use client';
import React, { useRef } from 'react';
import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Image from 'next/image';
import LogoMorph from './animations/LogoMorph';
import DorlisMorph from './animations/DorlisMorph';
import TranslatorMorph from './animations/TranslatorMorph';
import DominoMorph from './animations/DominoMorph';

gsap.registerPlugin(ScrollTrigger);

const heroData = {
  id: 'hero',
  title: 'Kwazé Kréyol : La plateforme interactive de la langue et de la culture martiniquaise.',
  logo: '/images/logo-kk.webp',
};

const pillarsData = [
  {
    id: 'section1',
    title: 'Jé Mo Kréyol',
    text: 'Défiez vos amis et enrichissez votre vocabulaire avec nos jeux de mots 100% créole.',
    morphComponent: LogoMorph,
    bgColor: '#FFD700', // Jaune bouton d'or
  },
  {
    id: 'section2',
    title: 'Jeux de Famille',
    text: "Plongez dans l'univers mystique du Dorlis (RPG inspiré du Loup-Garou) ou redécouvrez les Dominos aux règles de la Martinique.",
    morphComponent: DorlisMorph,
    bgColor: '#FF0000', // Rouge vif
  },
  {
    id: 'section3',
    title: 'Traducteur Intelligent',
    text: 'Passez du français au créole martiniquais grâce à notre dictionnaire enrichi par Raphaël Confiant.',
    morphComponent: TranslatorMorph,
    bgColor: '#D2691E', // Orange terreux
  },
  {
    id: 'section4',
    title: 'Dominos Mentor',
    text: 'Notez vos scores, analysez vos statistiques et rejoignez le classement virtuel des meilleurs joueurs.',
    morphComponent: DominoMorph,
    bgColor: '#006400', // Vert forêt
  },
];

const LandingPage = () => {
  const container = useRef(null);
  const heroSectionRef = useRef(null);
  const transitionSectionRef = useRef(null);
  const transitionTextRef = useRef(null);
  const sectionsRefs = useRef([]);
  const buttonsRefs = useRef([]);
  const morphRefs = useRef([]);

  useGSAP(
    () => {
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

      // Transition Section Fade-in
      gsap.from(transitionTextRef.current, {
        opacity: 0,
        y: 50,
        duration: 1,
        ease: 'power3.out',
        scrollTrigger: {
          trigger: transitionSectionRef.current,
          start: 'top 80%',
          toggleActions: 'play none none none',
        },
      });

      const cleanups = [];

      pillarsData.forEach((data, index) => {
        const section = sectionsRefs.current[index];
        const button = buttonsRefs.current[index];
        const morphTarget = morphRefs.current[index];

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
        if (morphTarget) {
          gsap.to(morphTarget, {
            morphSVG: `.morph-${data.id}-end`,
            duration: 1,
            ease: 'power1.inOut',
            scrollTrigger: {
              trigger: section,
              start: 'top top',
              end: 'bottom top',
              scrub: true,
            },
          });
        }

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
      {/* Hero Section */}
      <section
        ref={heroSectionRef}
        className="h-screen w-full bg-cover bg-center flex flex-col items-center justify-center"
        style={{ backgroundImage: "url('/images/bkg.webp')" }}
      >
        <Image
          src={heroData.logo}
          alt="Kwazé Kréyol Logo"
          width={512}
          height={512}
          className="w-1/3 h-auto mb-8"
        />
        <h1 className="text-4xl text-white font-bold text-center max-w-3xl">
          {heroData.title}
        </h1>
      </section>

      {/* Transition Section */}
      <section
        ref={transitionSectionRef}
        className="h-screen w-full flex items-center justify-center bg-madras-yellow/20"
      >
        <p ref={transitionTextRef} className="text-2xl text-center max-w-3xl">
          Kwazé Kréyol :{' '}
          <strong className="font-bold text-madras-red">
            Valoriser la langue créole martiniquaise
          </strong>{' '}
          à travers le numérique. Que ce soit pour apprendre, jouer ou échanger,
          notre mission est de mettre le créole au cœur du digital, avec{' '}
          <strong className="font-bold text-madras-red">
            respect, fierté et modernité
          </strong>
          .
        </p>
      </section>

      {/* Pillars Sections */}
      {pillarsData.map((data, index) => {
        const MorphComponent = data.morphComponent;
        return (
          <section
            key={data.id}
            ref={(el) => (sectionsRefs.current[index] = el)}
            className="h-screen w-full flex items-center justify-center"
            style={{ backgroundColor: data.bgColor }}
          >
            <div className="flex items-center justify-center w-full max-w-4xl">
              <div className="w-1/2">
                <MorphComponent
                  ref={(el) => (morphRefs.current[index] = el)}
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
