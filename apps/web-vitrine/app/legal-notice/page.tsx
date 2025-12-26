import React from 'react';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Mentions Légales',
  description: 'Consultez les mentions légales de Kwazé Kréyol.',
};

const LegalNoticePage = () => {
  return (
    <div className="bg-gray-900 text-white min-h-screen">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-4xl font-bold text-center mb-8">Mentions Légales</h1>
        <div className="bg-gray-800 rounded-lg p-8">
          <h2 className="text-2xl font-semibold mb-4">Éditeur du site</h2>
          <p className="mb-2">
            <strong>Nom :</strong> ITMade studio
          </p>
          <p className="mb-2">
            <strong>Statut juridique :</strong> SASU en cours d&apos;enregistrement
          </p>
          <p className="mb-2">
            <strong>Adresse :</strong> rue Perriolat, 97240 Le François, Martinique
          </p>
          <p>
            <strong>Contact :</strong>{' '}
            <a href="mailto:contact@itmade.fr" className="text-madras-yellow hover:text-madras-orange">
              contact@itmade.fr
            </a>
          </p>
        </div>
      </div>
    </div>
  );
};

export default LegalNoticePage;
