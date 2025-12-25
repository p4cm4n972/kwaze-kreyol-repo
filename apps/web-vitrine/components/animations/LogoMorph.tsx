"use client";

import React from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(MorphSVGPlugin);
}

interface LogoMorphProps {
  startClass: string;
  endClass: string;
}

const LogoMorph: React.FC<LogoMorphProps> = ({ startClass, endClass }) => {
  const initialPath =
    'M25,20 L35,20 L35,80 L25,80 Z M40,50 L70,20 L82,20 L55,50 L85,80 L72,80 L40,50 Z';
  const finalPath =
    'M20,20 L80,20 L80,80 L20,80 Z M20,40 L80,40 M20,60 L80,60 M40,20 L40,80 M60,20 L60,80';

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

export default LogoMorph;
