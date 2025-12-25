"use client";
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== "undefined") {
  gsap.registerPlugin(MorphSVGPlugin);
}

const TranslatorMorph: React.FC = () => {
  const svgRef = useRef<SVGSVGElement>(null);
  const pathRef = useRef<SVGPathElement>(null);

  const initialPath = "M20,30 L80,30 L80,70 L50,70 L30,90 L30,70 L20,70 Z";
  const finalPath = "M25,25 L50,25 L50,75 L25,75 Z M50,25 L75,25 L75,75 L50,75 Z";

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

export default TranslatorMorph;
