"use client";

import React from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(MorphSVGPlugin);
}

interface DorlisMorphProps {
  startClass: string;
  endClass: string;
}

const DorlisMorph: React.FC<DorlisMorphProps> = ({ startClass, endClass }) => {
  const initialPath = 'M50,20 A30,30 0 1,1 50,80 A25,25 0 1,0 50,20 Z';
  const finalPath =
    'M30,30 L70,30 L70,70 C70,85 30,85 30,70 Z M40,45 A5,5 0 1,0 45,45 Z M55,45 A5,5 0 1,0 60,45 Z';

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

export default DorlisMorph;
