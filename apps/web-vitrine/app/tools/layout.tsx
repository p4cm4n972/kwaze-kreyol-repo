import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Nos outils",
  description: "Découvre nos outils créoles martiniquais : traducteur français-créole Kozé Kwazé, compteur de points dominos Mét Double. Utilise-les gratuitement en ligne.",
  openGraph: {
    title: "Outils créoles - Kwazé Kréyol",
    description: "Traducteur créole martiniquais et outils numériques pour la langue créole. Gratuit et en ligne !",
    url: "https://kwazé-kréyol.fr/tools",
  },
};

export default function ToolsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
