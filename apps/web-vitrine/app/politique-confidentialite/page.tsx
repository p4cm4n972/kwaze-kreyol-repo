'use client';

import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Image from 'next/image';

export default function PolitiqueConfidentialite() {
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
            <span className="text-madras-yellow">Politique de confidentialité</span>
          </h1>

          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 md:p-8 lg:p-12 border border-white/20 shadow-2xl">
            <div className="space-y-8 text-white">
              {/* Introduction */}
              <div>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  ITMade Studio, éditeur de Kwazé Kréyol, accorde une grande importance à la protection de vos données personnelles. Cette politique de confidentialité explique quelles données nous collectons, comment nous les utilisons et quels sont vos droits.
                </p>
              </div>

              {/* Responsable du traitement */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Responsable du traitement des données
                </h2>
                <div className="space-y-2 text-sm sm:text-base md:text-lg">
                  <p><strong>Raison sociale :</strong> ITMade Studio</p>
                  <p><strong>Email :</strong> <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a></p>
                </div>
              </div>

              {/* Données collectées */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Données personnelles collectées
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  <strong>Sur le site web :</strong>
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li>Aucune donnée personnelle n&apos;est collectée via le site web vitrine</li>
                  <li>Pas de formulaire de contact en ligne</li>
                  <li>Pas de cookies de traçage ou d&apos;analyse</li>
                </ul>

                <p className="text-sm sm:text-base md:text-lg mb-4 mt-6">
                  <strong>Dans les applications mobiles :</strong>
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li>Données de jeu (scores, progression) stockées localement sur votre appareil</li>
                  <li>Aucune donnée n&apos;est transmise à des serveurs externes</li>
                  <li>Utilisation hors ligne privilégiée</li>
                </ul>
              </div>

              {/* Utilisation des données */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Utilisation des données
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  Les données que nous pourrions collecter sont utilisées uniquement pour :
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li>Assurer le bon fonctionnement des applications</li>
                  <li>Sauvegarder votre progression dans les jeux</li>
                  <li>Répondre à vos demandes de support (si vous nous contactez par email)</li>
                </ul>
              </div>

              {/* Conservation des données */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Conservation des données
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Les données de jeu sont stockées localement sur votre appareil et y restent jusqu&apos;à la désinstallation de l&apos;application. Aucune donnée n&apos;est conservée sur nos serveurs.
                </p>
              </div>

              {/* Partage des données */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Partage des données
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Nous ne vendons, n&apos;échangeons ni ne transférons vos données personnelles à des tiers. Vos données ne quittent pas votre appareil.
                </p>
              </div>

              {/* Vos droits */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Vos droits (RGPD)
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  Conformément au Règlement Général sur la Protection des Données (RGPD), vous disposez des droits suivants :
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li><strong>Droit d&apos;accès :</strong> obtenir la confirmation que des données vous concernant sont traitées</li>
                  <li><strong>Droit de rectification :</strong> corriger vos données inexactes</li>
                  <li><strong>Droit à l&apos;effacement :</strong> demander la suppression de vos données</li>
                  <li><strong>Droit à la limitation :</strong> limiter le traitement de vos données</li>
                  <li><strong>Droit d&apos;opposition :</strong> vous opposer au traitement de vos données</li>
                  <li><strong>Droit à la portabilité :</strong> recevoir vos données dans un format structuré</li>
                </ul>
                <p className="text-sm sm:text-base md:text-lg mt-4">
                  Pour exercer ces droits, contactez-nous à : <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a>
                </p>
              </div>

              {/* Sécurité */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Sécurité des données
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données contre tout accès non autorisé, modification, divulgation ou destruction.
                </p>
              </div>

              {/* Applications tierces */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Services tiers
                </h2>
                <p className="text-sm sm:text-base md:text-lg mb-4">
                  Nos applications sont distribuées via :
                </p>
                <ul className="list-disc list-inside space-y-2 text-sm sm:text-base md:text-lg ml-4">
                  <li><strong>Google Play Store</strong> (Android) - soumis à la politique de confidentialité de Google</li>
                  <li><strong>Apple App Store</strong> (iOS) - soumis à la politique de confidentialité d&apos;Apple</li>
                </ul>
                <p className="text-sm sm:text-base md:text-lg mt-4">
                  Ces plateformes peuvent collecter leurs propres données selon leurs politiques respectives.
                </p>
              </div>

              {/* Mineurs */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Protection des mineurs
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Nos applications sont adaptées à tous les âges. Nous ne collectons pas sciemment de données personnelles auprès d&apos;enfants de moins de 13 ans.
                </p>
              </div>

              {/* Modifications */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Modifications de la politique
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Nous nous réservons le droit de modifier cette politique de confidentialité à tout moment. Toute modification sera publiée sur cette page avec une date de mise à jour.
                </p>
              </div>

              {/* Contact */}
              <div>
                <h2 className="text-2xl md:text-3xl font-bold text-madras-yellow mb-4">
                  Nous contacter
                </h2>
                <p className="text-sm sm:text-base md:text-lg">
                  Pour toute question concernant cette politique de confidentialité ou vos données personnelles, contactez-nous à : <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange transition-colors">contact@itmade.fr</a>
                </p>
              </div>

              {/* Date de mise à jour */}
              <div className="pt-6 border-t border-white/20">
                <p className="text-sm text-white/70 text-center">
                  Dernière mise à jour : Décembre 2025
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
