import AboutPage from '@/components/AboutPage';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "À propos",
  description: "Découvrez l'histoire de Kwazé Kréyol, une initiative culturelle et technologique pour valoriser la langue créole martiniquaise à travers des outils numériques modernes.",
  openGraph: {
    title: "À propos de Kwazé Kréyol",
    description: "Notre mission : mettre le créole martiniquais au cœur du numérique avec respect, fierté et modernité.",
    url: "https://kwazé-kréyol.fr/about",
  },
};

export default function About() {
  return (
    <>
      <Navbar />
      <AboutPage />
      <Footer />
    </>
  );
}
