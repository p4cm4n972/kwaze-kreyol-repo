'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';

export default function CGU() {
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
            <span className="text-madras-yellow">Conditions Générales d&apos;Utilisation</span>
          </h1>

          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 border border-white/20 shadow-2xl">
            <div className="space-y-8 text-white">
              {/* Introduction */}
              <div>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  Les présentes Conditions Générales d&apos;Utilisation (CGU) régissent l&apos;utilisation du site web Kwazé Kréyol et des applications mobiles associées, édités par ITMade Studio.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  En accédant à nos services, vous acceptez sans réserve les présentes CGU.
                </p>
              </div>

              {/* Article 1 - Objet */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 1 - Objet
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Kwazé Kréyol est une plateforme éducative et ludique dédiée à l&apos;apprentissage et à la promotion de la langue et de la culture créole martiniquaise à travers des jeux interactifs.
                </p>
              </div>

              {/* Article 2 - Accès aux services */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 2 - Accès aux services
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  L&apos;accès au site web est gratuit. Les applications mobiles sont disponibles en téléchargement gratuit sur les plateformes Google Play Store et Apple App Store.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  ITMade Studio se réserve le droit de modifier, suspendre ou interrompre tout ou partie des services à tout moment, sans préavis.
                </p>
              </div>

              {/* Article 3 - Propriété intellectuelle */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 3 - Propriété intellectuelle
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  L&apos;ensemble des contenus présents sur le site et les applications (textes, images, sons, vidéos, logos, icônes, logiciels) sont la propriété exclusive d&apos;ITMade Studio ou de ses partenaires.
                </p>
                <p className="text-sm sm:text-base md:text-lg">
                  Toute reproduction, représentation, modification ou exploitation non autorisée est strictement interdite et constitue une contrefaçon sanctionnée par le Code de la propriété intellectuelle.
                </p>
              </div>

              {/* Article 4 - Utilisation des services */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 4 - Utilisation des services
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  L&apos;utilisateur s&apos;engage à :
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li>Utiliser les services de manière conforme à leur destination</li>
                  <li>Ne pas tenter de contourner les mesures de sécurité</li>
                  <li>Ne pas utiliser les services à des fins illicites ou contraires aux bonnes mœurs</li>
                  <li>Respecter les droits de propriété intellectuelle</li>
                </ul>
              </div>

              {/* Article 5 - Données personnelles */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 5 - Données personnelles
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Le traitement des données personnelles est détaillé dans notre <a href="/politique-confidentialite" className="text-madras-yellow hover:text-madras-orange transition-colors">Politique de Confidentialité</a>. Nos applications fonctionnent principalement hors ligne et ne collectent pas de données personnelles.
                </p>
              </div>

              {/* Article 6 - Responsabilité */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 6 - Limitation de responsabilité
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  ITMade Studio s&apos;efforce d&apos;assurer la disponibilité et la qualité de ses services mais ne peut garantir :
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li>L&apos;absence d&apos;interruption ou d&apos;erreurs</li>
                  <li>La compatibilité avec tous les appareils</li>
                  <li>L&apos;absence de virus ou éléments nuisibles</li>
                </ul>
                <p className="text-sm sm:text-base md:text-lg mt-4">
                  ITMade Studio ne saurait être tenu responsable des dommages directs ou indirects résultant de l&apos;utilisation des services.
                </p>
              </div>

              {/* Article 7 - Liens externes */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 7 - Liens externes
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Le site peut contenir des liens vers des sites externes. ITMade Studio n&apos;exerce aucun contrôle sur ces sites et décline toute responsabilité quant à leur contenu.
                </p>
              </div>

              {/* Article 8 - Modifications */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 8 - Modification des CGU
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  ITMade Studio se réserve le droit de modifier les présentes CGU à tout moment. Les modifications entrent en vigueur dès leur publication sur le site. L&apos;utilisation continue des services vaut acceptation des nouvelles conditions.
                </p>
              </div>

              {/* Article 9 - Droit applicable */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 9 - Droit applicable
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Les présentes CGU sont régies par le droit français. En cas de litige, les tribunaux compétents seront ceux du ressort du siège social d&apos;ITMade Studio, à savoir Fort-de-France (Martinique).
                </p>
              </div>

              {/* Article 10 - Contact */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Article 10 - Contact
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Pour toute question relative aux présentes CGU, vous pouvez nous contacter à : <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a>
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
