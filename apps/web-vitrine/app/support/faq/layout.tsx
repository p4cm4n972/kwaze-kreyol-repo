import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "FAQ",
  description: "Questions fréquentes sur Kwazé Kréyol : fonctionnement hors ligne, téléchargements, gratuité de l'application et suggestions d'améliorations.",
  openGraph: {
    title: "FAQ - Kwazé Kréyol",
    description: "Réponses aux questions les plus fréquentes sur Kwazé Kréyol",
    url: "https://kwaze-kreyol.com/support/faq",
  },
};

export default function FAQLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
