"use client";
import React, { useRef, useEffect } from 'react';
import { gsap } from 'gsap';

interface CardProps {
  icon: React.ReactNode;
  title: string;
  text: string;
}

const Card: React.FC<CardProps> = ({ icon, title, text }) => {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const fillRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const button = buttonRef.current;
    const fill = fillRef.current;
    if (!button || !fill) return;

    const tl = gsap.timeline({ paused: true });
    tl.to(fill, {
      width: '100%',
      duration: 0.5,
      ease: 'power2.inOut'
    });

    const handleMouseEnter = () => tl.play();
    const handleMouseLeave = () => tl.reverse();

    button.addEventListener('mouseenter', handleMouseEnter);
    button.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      button.removeEventListener('mouseenter', handleMouseEnter);
      button.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, []);

  return (
    <div className="bg-gray-800 bg-opacity-40 backdrop-blur-md rounded-lg p-6 flex flex-col items-center text-center shadow-lg">
      <div className="w-24 h-24 mb-4">{icon}</div>
      <h3 className="text-xl font-bold text-white mb-2">{title}</h3>
      <p className="text-gray-300 mb-4">{text}</p>
      <button
        ref={buttonRef}
        className="relative overflow-hidden bg-transparent border border-orange-400 text-orange-400 font-bold py-2 px-4 rounded transition-colors duration-300"
      >
        <span
          ref={fillRef}
          className="absolute top-0 left-0 h-full bg-orange-600"
          style={{ width: '0%', zIndex: -1 }}
        ></span>
        En savoir plus
      </button>
    </div>
  );
};

export default Card;
