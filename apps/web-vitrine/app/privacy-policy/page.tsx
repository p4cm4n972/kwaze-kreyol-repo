import React from 'react';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Politique de Confidentialité',
  description: 'Consultez la politique de confidentialité de Kwazé Kréyol.',
};

const PrivacyPolicyPage = () => {
  return (
    <div className="bg-gray-900 text-white min-h-screen">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <h1 className="text-4xl font-bold text-center mb-8">Politique de Confidentialité</h1>
        <div className="bg-gray-800 rounded-lg p-8">
          <p>
            Contenu de la politique de confidentialité à venir.
          </p>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicyPage;
