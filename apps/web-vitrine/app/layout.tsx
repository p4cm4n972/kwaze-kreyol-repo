import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "Kwazé Kréyol - Plateforme interactive de la langue créole martiniquaise",
    template: "%s | Kwazé Kréyol"
  },
  description: "Découvrez la plateforme interactive dédiée à la langue et la culture créole martiniquaise. Jeux de mots, traducteur, dominos et bien plus pour valoriser le créole à travers le numérique.",
  keywords: ["créole martiniquais", "langue créole", "culture martiniquaise", "jeux créoles", "traducteur créole", "Martinique", "patrimoine linguistique", "apprentissage créole"],
  authors: [{ name: "ITMade Studio", url: "https://itmade.studio" }],
  creator: "ITMade Studio",
  publisher: "ITMade Studio",
  metadataBase: new URL("https://kwaze-kreyol.com"),
  alternates: {
    canonical: "/",
  },
  openGraph: {
    type: "website",
    locale: "fr_FR",
    url: "https://kwaze-kreyol.com",
    siteName: "Kwazé Kréyol",
    title: "Kwazé Kréyol - Plateforme interactive de la langue créole martiniquaise",
    description: "Découvrez la plateforme interactive dédiée à la langue et la culture créole martiniquaise.",
    images: [
      {
        url: "/images/logo-kk.webp",
        width: 512,
        height: 512,
        alt: "Logo Kwazé Kréyol",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Kwazé Kréyol - Plateforme interactive de la langue créole martiniquaise",
    description: "Découvrez la plateforme interactive dédiée à la langue et la culture créole martiniquaise.",
    images: ["/images/logo-kk.webp"],
    creator: "@itmade_studio",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'Kwazé Kréyol',
    description: 'Plateforme interactive dédiée à la langue et la culture créole martiniquaise',
    url: 'https://kwaze-kreyol.com',
    inLanguage: 'fr-FR',
    publisher: {
      '@type': 'Organization',
      name: 'ITMade Studio',
      url: 'https://itmade.studio',
      email: 'contact@itmade.fr',
    },
    potentialAction: {
      '@type': 'SearchAction',
      target: 'https://kwaze-kreyol.com/search?q={search_term_string}',
      'query-input': 'required name=search_term_string',
    },
  };

  return (
    <html lang="fr">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
