"use client";

import React, { forwardRef } from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(MorphSVGPlugin);
}

interface TranslatorMorphProps {
  startClass: string;
  endClass: string;
}

const TranslatorMorph = forwardRef<SVGPathElement, TranslatorMorphProps>(
  ({ startClass, endClass }, ref) => {
    const initialPath = 'M20,30 L80,30 L80,70 L50,70 L30,90 L30,70 L20,70 Z';
    const finalPath =
      'M25,25 L50,25 L50,75 L25,75 Z M50,25 L75,25 L75,75 L50,75 Z';

    return (
      <svg width="100" height="100" viewBox="0 0 100 100">
        <path
          ref={ref}
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
  },
);

TranslatorMorph.displayName = 'TranslatorMorph';

export default TranslatorMorph;
