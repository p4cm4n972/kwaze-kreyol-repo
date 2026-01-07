import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Conditions Générales d'Utilisation",
  description: "CGU de Kwazé Kréyol : conditions d'accès aux services, propriété intellectuelle, responsabilité, droit applicable.",
  openGraph: {
    title: "CGU - Kwazé Kréyol",
    description: "Conditions générales d'utilisation des services Kwazé Kréyol.",
    url: "https://kwazé-kréyol.fr/cgu",
  },
  robots: {
    index: false,
    follow: true,
  },
};

export default function CGULayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
