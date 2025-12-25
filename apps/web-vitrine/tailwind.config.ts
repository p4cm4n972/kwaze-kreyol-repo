import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'madras-yellow': '#FFD700', // Jaune bouton d'or
        'madras-red': '#FF0000',    // Rouge vif
        'madras-orange': '#D2691E', // Orange terreux
        'madras-green': '#006400',  // Vert forêt
      },
    },
  },
  plugins: [],
};

export default config;
