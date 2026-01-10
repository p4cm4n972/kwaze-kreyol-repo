'use client';
import { useState, useEffect } from 'react';
import Image from 'next/image';
import Link from 'next/link';

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const infoNavItems = [
    { label: 'Accueil', href: '/' },
    { label: 'À propos', href: '/about' },
    { label: 'Support', href: '/support' },
  ];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? 'bg-black/90 backdrop-blur-md shadow-lg' : 'bg-black/60 backdrop-blur-sm'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Logo */}
          <div className="flex-shrink-0">
            <Link href="/" className="flex items-center">
              <Image
                src="/images/favicon.webp"
                alt="Kwazé Kréyol"
                width={50}
                height={50}
                className="h-12 w-auto"
              />
            </Link>
          </div>

          {/* Menu Desktop */}
          <div className="hidden md:flex items-center flex-1 justify-between ml-10">
            {/* Liens informationnels */}
            <div className="flex items-baseline space-x-6">
              {infoNavItems.map((item) => (
                <Link
                  key={item.label}
                  href={item.href}
                  className="text-white hover:text-madras-yellow transition-colors duration-200 px-3 py-2 text-lg font-medium"
                >
                  {item.label}
                </Link>
              ))}
            </div>

            {/* Séparateur visuel */}
            <div className="h-8 w-px bg-white/30 mx-4"></div>

            {/* Liens d'action */}
            <div className="flex items-baseline space-x-4">
              <Link
                href="/traduction"
                className="text-white hover:bg-yellow-400 hover:text-black transition-all duration-200 px-5 py-2.5 text-lg font-bold rounded-lg shadow-lg hover:scale-105"
                style={{ backgroundColor: '#006400', borderWidth: '2px', borderColor: '#FFFFFF' }}
              >
                Traducteur
              </Link>
              <a
                href="https://jé.kwazé-kréyol.fr"
                target="_blank"
                rel="noopener noreferrer"
                className="text-white hover:bg-yellow-400 hover:text-black transition-all duration-200 px-5 py-2.5 text-lg font-bold rounded-lg shadow-lg hover:scale-105"
                style={{ backgroundColor: '#FF0000', borderWidth: '2px', borderColor: '#FFFFFF' }}
              >
                Jouer en ligne
              </a>
            </div>
          </div>

          {/* Bouton Menu Burger */}
          <div className="md:hidden">
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="inline-flex items-center justify-center p-2 rounded-md text-white hover:text-madras-yellow focus:outline-none focus:ring-2 focus:ring-inset focus:ring-madras-yellow transition-colors"
              aria-expanded="false"
            >
              <span className="sr-only">Ouvrir le menu</span>
              {!isOpen ? (
                <svg
                  className="block h-8 w-8"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              ) : (
                <svg
                  className="block h-8 w-8"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Menu Mobile */}
      <div
        className={`md:hidden transition-all duration-300 ease-in-out ${
          isOpen
            ? 'max-h-96 opacity-100'
            : 'max-h-0 opacity-0 overflow-hidden'
        }`}
      >
        <div className="px-2 pt-2 pb-3 space-y-3 sm:px-3 bg-black/95 backdrop-blur-md">
          {/* Section Actions */}
          <div className="space-y-2 pb-3 border-b border-white/20">
            <p className="text-xs font-bold uppercase px-3 mb-2" style={{ color: '#FFD700' }}>Actions</p>
            <Link
              href="/traduction"
              onClick={() => setIsOpen(false)}
              className="text-white hover:bg-yellow-400 hover:text-black block px-4 py-3 rounded-lg text-base font-bold transition-all duration-200 text-center shadow-lg"
              style={{ backgroundColor: '#006400', borderWidth: '2px', borderColor: '#FFFFFF' }}
            >
              Traducteur
            </Link>
            <a
              href="https://jé.kwazé-kréyol.fr"
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => setIsOpen(false)}
              className="text-white hover:bg-yellow-400 hover:text-black block px-4 py-3 rounded-lg text-base font-bold transition-all duration-200 text-center shadow-lg"
              style={{ backgroundColor: '#FF0000', borderWidth: '2px', borderColor: '#FFFFFF' }}
            >
              Jouer en ligne
            </a>
          </div>

          {/* Section Info */}
          <div className="space-y-1">
            <p className="text-white/60 text-xs font-bold uppercase px-3 mb-2">Navigation</p>
            {infoNavItems.map((item) => (
              <Link
                key={item.label}
                href={item.href}
                onClick={() => setIsOpen(false)}
                className="text-white hover:text-madras-yellow hover:bg-white/10 block px-3 py-3 rounded-md text-base font-medium transition-all duration-200"
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
