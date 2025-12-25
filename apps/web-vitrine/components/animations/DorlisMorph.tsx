"use client";
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { MorphSVGPlugin } from 'gsap/MorphSVGPlugin';

if (typeof window !== "undefined") {
  gsap.registerPlugin(MorphSVGPlugin);
}

const DorlisMorph: React.FC = () => {
  const svgRef = useRef<SVGSVGElement>(null);
  const pathRef = useRef<SVGPathElement>(null);

  const initialPath = "M50,20 A30,30 0 1,1 50,80 A25,25 0 1,0 50,20 Z";
  const finalPath = "M30,30 L70,30 L70,70 C70,85 30,85 30,70 Z M40,45 A5,5 0 1,0 45,45 Z M55,45 A5,5 0 1,0 60,45 Z";

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

export default DorlisMorph;
