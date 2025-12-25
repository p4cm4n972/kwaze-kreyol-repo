import Card from '@/components/Card';
import DominoMorph from '@/components/animations/DominoMorph';
import DorlisMorph from '@/components/animations/DorlisMorph';
import LogoMorph from '@/components/animations/LogoMorph';
import TranslatorMorph from '@/components/animations/TranslatorMorph';

export default function Home() {
  return (
    <div className="bg-gray-900 min-h-screen p-8 flex flex-col items-center">
      <div className="mb-12">
        <LogoMorph />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl w-full">
        <Card
          icon={<LogoMorph />}
          title="Jé Mo Kréyol"
          text="Défiez vos amis et enrichissez votre vocabulaire avec nos jeux de mots croisés et Scrabble 100% créole."
        />
        <Card
          icon={<DorlisMorph />}
          title="L'Ombre du Dorlis"
          text="Un jeu de rôle immersif inspiré du Loup-Garou. Saurez-vous démasquer le Dorlis avant qu'il ne soit trop tard ?"
        />
        <Card
          icon={<TranslatorMorph />}
          title="Traducteur Intelligent"
          text="Passez du français au créole martiniquais instantanément grâce à notre dictionnaire enrichi par les œuvres de Raphaël Confiant."
        />
        <Card
          icon={<DominoMorph />}
          title="Dominos Mentor"
          text="Ne perdez plus le fil de vos parties. Notez vos scores, analysez vos statistiques et grimpez dans le classement national."
        />
      </div>
    </div>
  );
}
