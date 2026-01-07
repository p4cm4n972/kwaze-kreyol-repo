import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Mentions légales",
  description: "Mentions légales du site Kwazé Kréyol - Informations sur l'éditeur, l'hébergement, la propriété intellectuelle et la protection des données.",
  openGraph: {
    title: "Mentions légales - Kwazé Kréyol",
    description: "Informations légales sur Kwazé Kréyol",
    url: "https://kwazé-kréyol.fr/mentions-legales",
  },
};

export default function MentionsLegalesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
