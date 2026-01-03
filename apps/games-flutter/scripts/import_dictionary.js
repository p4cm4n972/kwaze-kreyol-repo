#!/usr/bin/env node

/**
 * Script d'import du dictionnaire JSON vers Supabase
 *
 * Usage: node import_dictionary.js
 *
 * Prérequis:
 * - npm install @supabase/supabase-js
 * - Définir les variables d'environnement SUPABASE_URL et SUPABASE_SERVICE_KEY
 */

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Variables d\'environnement manquantes:');
  console.error('   SUPABASE_URL et SUPABASE_SERVICE_KEY doivent être définies');
  console.error('');
  console.error('Exemple:');
  console.error('   export SUPABASE_URL=https://xxxxx.supabase.co');
  console.error('   export SUPABASE_SERVICE_KEY=eyJhbGc...');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Chemins des fichiers dictionnaire
const dictionnaireFiles = [
  path.join(__dirname, '../../../data/dictionnaires/dictionnaire_A.json'),
  // Ajouter ici d'autres lettres quand elles seront disponibles
  // path.join(__dirname, '../../../data/dictionnaires/dictionnaire_B.json'),
];

async function importDictionnaire() {
  console.log('🔄 Import du dictionnaire créole vers Supabase...\n');

  let totalImported = 0;
  let totalSkipped = 0;
  let totalErrors = 0;

  for (const filePath of dictionnaireFiles) {
    if (!fs.existsSync(filePath)) {
      console.log(`⏭️  Fichier ignoré (non trouvé): ${path.basename(filePath)}`);
      continue;
    }

    console.log(`📖 Lecture de ${path.basename(filePath)}...`);
    const jsonData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    console.log(`   ${jsonData.length} mots trouvés\n`);

    for (const entry of jsonData) {
      const mot = entry.mot;

      for (const def of entry.definitions) {
        try {
          // Extraire le premier exemple (s'il existe)
          const firstExample = def.exemples && def.exemples.length > 0 ? def.exemples[0] : null;

          const wordData = {
            word: mot,
            language: 'creole',
            translation: def.traduction,
            nature: def.nature || null,
            example_creole: firstExample ? firstExample.creole : null,
            example_francais: firstExample ? firstExample.francais : null,
            synonymes: def.synonymes || [],
            variantes: def.variantes || [],
            sens_num: def.sens_num || 1,
            explication_usage: def.explication_usage || null,
            is_official: true,
          };

          // Insérer dans Supabase (ou ignorer si déjà existant)
          const { data, error } = await supabase
            .from('dictionary_words')
            .upsert([wordData], {
              onConflict: 'word,language,sens_num',
              ignoreDuplicates: false
            });

          if (error) {
            if (error.code === '23505') { // Duplicate key
              totalSkipped++;
            } else {
              console.error(`   ❌ Erreur pour "${mot}" (sens ${def.sens_num}):`, error.message);
              totalErrors++;
            }
          } else {
            totalImported++;
          }

          // Ajouter aussi la traduction inverse (français -> créole)
          const reverseWordData = {
            word: def.traduction,
            language: 'francais',
            translation: mot,
            nature: def.nature || null,
            example_creole: firstExample ? firstExample.francais : null,
            example_francais: firstExample ? firstExample.creole : null,
            sens_num: def.sens_num || 1,
            is_official: true,
          };

          const { error: reverseError } = await supabase
            .from('dictionary_words')
            .upsert([reverseWordData], {
              onConflict: 'word,language,sens_num',
              ignoreDuplicates: false
            });

          if (!reverseError || reverseError.code === '23505') {
            if (!reverseError) totalImported++;
            else totalSkipped++;
          } else {
            totalErrors++;
          }

        } catch (err) {
          console.error(`   ❌ Erreur pour "${mot}":`, err.message);
          totalErrors++;
        }
      }
    }

    console.log(`✅ ${path.basename(filePath)} traité\n`);
  }

  console.log('═══════════════════════════════════════');
  console.log('📊 Résumé de l\'import:');
  console.log(`   ✅ Importés: ${totalImported}`);
  console.log(`   ⏭️  Ignorés (doublons): ${totalSkipped}`);
  console.log(`   ❌ Erreurs: ${totalErrors}`);
  console.log('═══════════════════════════════════════\n');

  if (totalErrors > 0) {
    console.log('⚠️  Certaines entrées n\'ont pas pu être importées.');
    console.log('   Vérifiez les erreurs ci-dessus pour plus de détails.\n');
  } else {
    console.log('🎉 Import terminé avec succès!\n');
  }
}

// Exécuter l'import
importDictionnaire()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\n❌ Erreur fatale:', error);
    process.exit(1);
  });
