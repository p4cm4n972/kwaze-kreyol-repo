"use client";

import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== "undefined") {
  gsap.registerPlugin(MorphSVGPlugin);
}

const LogoMorph: React.FC = () => {
  const svgRef = useRef<SVGSVGElement>(null);
  const pathRef = useRef<SVGPathElement>(null);

  const initialPath = "M25,20 L35,20 L35,80 L25,80 Z M40,50 L70,20 L82,20 L55,50 L85,80 L72,80 L40,50 Z";
  const finalPath = "M20,20 L80,20 L80,80 L20,80 Z M20,40 L80,40 M20,60 L80,60 M40,20 L40,80 M60,20 L60,80";

  useEffect(() => {
    const svgElement = svgRef.current;

    const handleMouseEnter = () => {
      gsap.to(pathRef.current, {
        duration: 0.8,
        ease: "elastic.inOut(1, 0.5)",
        morphSVG: finalPath
      });
    };

    const handleMouseLeave = () => {
      gsap.to(pathRef.current, {
        duration: 0.8,
        ease: "elastic.inOut(1, 0.5)",
        morphSVG: initialPath
      });
    };

    if (svgElement) {
      svgElement.addEventListener('mouseenter', handleMouseEnter);
      svgElement.addEventListener('mouseleave', handleMouseLeave);
    }

    return () => {
      if (svgElement) {
        svgElement.removeEventListener('mouseenter', handleMouseEnter);
        svgElement.removeEventListener('mouseleave', handleMouseLeave);
      }
    };
  }, [initialPath, finalPath]);

  return (
    <div className="bg-gray-900 min-h-screen flex items-center justify-center">
      <svg
        ref={svgRef}
        width="100"
        height="100"
        viewBox="0 0 100 100"
        className="cursor-pointer"
      >
        <path
          ref={pathRef}
          d={initialPath}
          fill="none"
          stroke="white"
          strokeWidth="2"
        />
      </svg>
    </div>
  );
};

export default LogoMorph;
