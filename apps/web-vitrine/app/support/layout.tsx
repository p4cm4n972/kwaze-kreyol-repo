import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Support",
  description: "Besoin d'aide avec Kwazé Kréyol ? Consultez notre FAQ et contactez notre équipe pour toute question ou suggestion concernant nos jeux et outils créoles.",
  openGraph: {
    title: "Support - Kwazé Kréyol",
    description: "FAQ et contact - Notre équipe est là pour vous aider",
    url: "https://kwaze-kreyol.com/support",
  },
};

export default function SupportLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
