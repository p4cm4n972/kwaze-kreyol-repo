import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Politique de confidentialité",
  description: "Politique de confidentialité de Kwazé Kréyol - Comment nous protégeons vos données personnelles et respectons votre vie privée conformément au RGPD.",
  openGraph: {
    title: "Politique de confidentialité - Kwazé Kréyol",
    description: "Protection de vos données personnelles sur Kwazé Kréyol",
    url: "https://kwaze-kreyol.com/politique-confidentialite",
  },
};

export default function PolitiqueConfidentialiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
