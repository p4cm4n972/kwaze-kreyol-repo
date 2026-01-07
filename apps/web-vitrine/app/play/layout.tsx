import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Nos jeux",
  description: "Découvre nos jeux 100% créole martiniquais : Mots Mawon, Skrabb, Double Siz et plus encore. Joue en ligne gratuitement ou télécharge les applications.",
  openGraph: {
    title: "Jeux créoles - Kwazé Kréyol",
    description: "Joue à nos jeux créoles martiniquais : mots cachés, scrabble, dominos. Gratuit et en ligne !",
    url: "https://kwazé-kréyol.fr/play",
  },
};

export default function PlayLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
