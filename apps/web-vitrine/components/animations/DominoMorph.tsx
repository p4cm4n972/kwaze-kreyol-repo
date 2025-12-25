"use client";

import React from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(MorphSVGPlugin);
}

interface DominoMorphProps {
  startClass: string;
  endClass: string;
}

const DominoMorph: React.FC<DominoMorphProps> = ({ startClass, endClass }) => {
  const initialPath =
    'M30,20 L70,20 L70,80 L30,80 Z M30,50 L70,50 M45,35 A5,5 0 1,0 55,35 Z M45,65 A5,5 0 1,0 55,65 Z';
  const finalPath =
    'M10,80 L35,80 L35,40 L65,40 L65,80 L90,80 L90,60 L10,60 Z';

  return (
    <svg width="100" height="100" viewBox="0 0 100 100">
      <path
        className={startClass}
        d={initialPath}
        fill="none"
        stroke="white"
        strokeWidth="2"
      />
      <path
        className={endClass}
        d={finalPath}
        fill="none"
        stroke="white"
        strokeWidth="2"
        style={{ display: 'none' }}
      />
    </svg>
  );
};

export default DominoMorph;
