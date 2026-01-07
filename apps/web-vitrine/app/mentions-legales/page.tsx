'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';

export default function MentionsLegales() {
  return (
    <>
      <Navbar />
      <section
        className="min-h-screen w-full bg-cover bg-center py-20 md:py-32 px-4 flex items-center justify-center relative bg-responsive"
      >
        {/* Cadres décoratifs */}
        <div className="absolute top-0 left-0 w-32 h-32 md:w-64 md:h-64 opacity-30 md:opacity-50">
          <Image
            src="/images/cadre-haut-gauche.webp"
            alt=""
            width={256}
            height={256}
            className="w-full h-full object-contain"
          />
        </div>
        <div className="absolute top-0 right-0 w-32 h-32 md:w-64 md:h-64 opacity-30 md:opacity-50">
          <Image
            src="/images/cadre-haut-droite.webp"
            alt=""
            width={256}
            height={256}
            className="w-full h-full object-contain"
          />
        </div>

        <div className="max-w-5xl mx-auto relative z-10 w-full">
          {/* Title */}
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-8 md:mb-12 text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.8)]">
            <span className="text-madras-yellow">Mentions légales</span>
          </h1>

          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 border border-white/20 shadow-2xl">
            <div className="space-y-8 text-white">
              {/* Éditeur */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Éditeur du site
                </h2>
                <div className="space-y-2 text-sm sm:text-base md:text-lg">
                  <p><strong>Raison sociale :</strong> ITMade Studio</p>
                  <p><strong>Forme juridique :</strong> SASU (en cours d&apos;immatriculation)</p>
                  <p><strong>SIRET :</strong> En cours d&apos;attribution</p>
                  <p><strong>Siège social :</strong> Quartier Perriolat, 97240 Le François, Martinique</p>
                  <p><strong>Email :</strong> <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a></p>
                  <p><strong>Directeur de publication :</strong> Manuel ADELE</p>
                </div>
              </div>

              {/* Hébergement */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Hébergement
                </h2>
                <div className="space-y-2 text-sm sm:text-base md:text-lg">
                  <p><strong>Hébergeur :</strong> Vercel Inc.</p>
                  <p><strong>Adresse :</strong> 340 S Lemon Ave #4133, Walnut, CA 91789, USA</p>
                  <p><strong>Site web :</strong> <a href="https://vercel.com" target="_blank" rel="noopener noreferrer" className="text-madras-yellow hover:text-madras-orange transition-colors">vercel.com</a></p>
                </div>
              </div>

              {/* Propriété intellectuelle */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Propriété intellectuelle
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  L&apos;ensemble du contenu de ce site (textes, images, vidéos, logos, icônes) est la propriété exclusive d&apos;ITMade Studio, sauf mention contraire.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  Toute reproduction, distribution, modification, adaptation, retransmission ou publication de ces différents éléments est strictement interdite sans l&apos;accord express par écrit d&apos;ITMade Studio.
                </p>
              </div>

              {/* Données personnelles */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Protection des données personnelles
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  Conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés, vous disposez d&apos;un droit d&apos;accès, de rectification, de suppression et d&apos;opposition aux données personnelles vous concernant.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  Pour exercer ces droits, contactez-nous à : <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a>
                </p>
              </div>

              {/* Cookies */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Cookies
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Ce site n&apos;utilise pas de cookies de traçage. Seuls des cookies techniques nécessaires au bon fonctionnement du site peuvent être utilisés.
                </p>
              </div>

              {/* Responsabilité */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Limitation de responsabilité
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  ITMade Studio s&apos;efforce d&apos;assurer l&apos;exactitude et la mise à jour des informations diffusées sur ce site. Toutefois, ITMade Studio ne peut garantir l&apos;exactitude, la précision ou l&apos;exhaustivité des informations mises à disposition sur ce site.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  ITMade Studio décline toute responsabilité pour toute imprécision, inexactitude ou omission portant sur des informations disponibles sur ce site.
                </p>
              </div>

              {/* Droit applicable */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Droit applicable
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Les présentes mentions légales sont régies par le droit français. En cas de litige et à défaut d&apos;accord amiable, le tribunal compétent sera celui du ressort du siège social d&apos;ITMade Studio.
                </p>
              </div>

              {/* Date de mise à jour */}
              <div className="pt-6 border-t border-white/20">
                <p className="text-sm text-white/70 text-center">
                  Dernière mise à jour : Janvier 2026
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
      <Footer />
    </>
  );
}
