import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Mots Mawon",
  description: "Jeu de mots cachés en créole martiniquais. Retrouve les mots dissimulés dans la grille et améliore ton vocabulaire créole !",
  openGraph: {
    title: "Mots Mawon - Kwazé Kréyol",
    description: "Jeu de mots cachés 100% créole",
    url: "https://kwaze-kreyol.com/play/mots-mawon",
  },
};

export default function MotsMawonLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
