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
  metadataBase: new URL("https://kwazé-kréyol.fr"),
  alternates: {
    canonical: "/",
  },
  icons: {
    icon: [
      { url: "/images/favicon.ico", sizes: "any" },
      { url: "/images/favicon.webp", type: "image/webp" },
    ],
    shortcut: "/images/favicon.ico",
    apple: "/images/favicon.webp",
  },
  openGraph: {
    type: "website",
    locale: "fr_FR",
    url: "https://kwazé-kréyol.fr",
    siteName: "Kwazé Kréyol",
    title: "Kwazé Kréyol - Plateforme interactive de la langue créole martiniquaise",
    description: "Découvrez la plateforme interactive dédiée à la langue et la culture créole martiniquaise.",
    images: [
      {
        url: "/images/social-preview.png",
        width: 1200,
        height: 630,
        alt: "Kwazé Kréyol - Jeux et outils créoles martiniquais",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Kwazé Kréyol - Plateforme interactive de la langue créole martiniquaise",
    description: "Découvrez la plateforme interactive dédiée à la langue et la culture créole martiniquaise.",
    images: ["/images/social-preview.png"],
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
  const jsonLdWebSite = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'Kwazé Kréyol',
    description: 'Plateforme interactive dédiée à la langue et la culture créole martiniquaise',
    url: 'https://kwazé-kréyol.fr',
    inLanguage: 'fr-FR',
    publisher: {
      '@type': 'Organization',
      name: 'ITMade Studio',
      url: 'https://itmade.studio',
      logo: {
        '@type': 'ImageObject',
        url: 'https://kwazé-kréyol.fr/images/logo-kk.webp',
        width: 512,
        height: 512,
      },
      email: 'contact@itmade.fr',
      foundingDate: '2024',
      foundingLocation: {
        '@type': 'Place',
        name: 'Martinique',
      },
    },
    potentialAction: {
      '@type': 'SearchAction',
      target: 'https://kwazé-kréyol.fr/search?q={search_term_string}',
      'query-input': 'required name=search_term_string',
    },
    about: {
      '@type': 'Thing',
      name: 'Langue créole martiniquaise',
      description: 'Patrimoine linguistique et culturel de la Martinique',
    },
  };

  const jsonLdOrganization = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'Kwazé Kréyol',
    alternateName: 'Kwaze Kreyol',
    url: 'https://kwazé-kréyol.fr',
    logo: 'https://kwazé-kréyol.fr/images/logo-kk.webp',
    description: 'Plateforme dédiée à la valorisation de la langue et culture créole martiniquaise à travers des jeux interactifs et outils numériques',
    sameAs: [
      'https://jeux.kwazé-kréyol.fr',
    ],
    contactPoint: {
      '@type': 'ContactPoint',
      email: 'contact@itmade.fr',
      contactType: 'customer service',
      availableLanguage: ['fr-FR', 'fr-MQ'],
    },
  };

  const jsonLdBreadcrumb = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      {
        '@type': 'ListItem',
        position: 1,
        name: 'Accueil',
        item: 'https://kwazé-kréyol.fr',
      },
    ],
  };

  return (
    <html lang="fr">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdWebSite) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdOrganization) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBreadcrumb) }}
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
