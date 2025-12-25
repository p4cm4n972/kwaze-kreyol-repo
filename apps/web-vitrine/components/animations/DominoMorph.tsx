"use client";
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== "undefined") {
  gsap.registerPlugin(MorphSVGPlugin);
}

const DominoMorph: React.FC = () => {
  const svgRef = useRef<SVGSVGElement>(null);
  const pathRef = useRef<SVGPathElement>(null);

  const initialPath = "M30,20 L70,20 L70,80 L30,80 Z M35,50 L65,50 M45,35 A5,5 0 1,0 55,35 Z M45,65 A5,5 0 1,0 55,65 Z";
  const finalPath = "M10,80 L35,80 L35,40 L65,40 L65,80 L90,80 L90,60 L10,60 Z";

  useEffect(() => {
    const svgElement = svgRef.current;
    if (!svgElement) return;

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

    svgElement.addEventListener('mouseenter', handleMouseEnter);
    svgElement.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      svgElement.removeEventListener('mouseenter', handleMouseEnter);
      svgElement.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [initialPath, finalPath]);

  return (
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
  );
};

export default DominoMorph;
