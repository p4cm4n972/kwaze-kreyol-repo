import React from 'react';

const Footer = () => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-black/90 backdrop-blur-sm text-white py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <p className="text-lg">
            © {currentYear}{' '}
            <a
              href="https://itmade.studio"
              target="_blank"
              rel="noopener noreferrer"
              className="text-madras-yellow hover:text-madras-orange transition-colors duration-200 font-semibold"
            >
              ITMade Studio
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
