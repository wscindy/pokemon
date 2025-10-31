import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const { Pool } = pg;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const pool = new Pool({
  user: 'liweixuan',
  host: 'localhost',
  database: 'pokemon_tcg_development',
  password: '1234',
  port: 5432,
});

const dataDir = path.join(__dirname, 'public', 'data_tc');

async function processCard(filePath, setFolderName) {
  try {
    const fileContent = await fs.readFile(filePath, 'utf-8');
    const card = JSON.parse(fileContent);
    const cardUniqueId = `${setFolderName}-${card.number}`;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(`
        INSERT INTO cards (card_unique_id, name, img_url, card_type, stage, hp, pokedex_number, 
          evolve_from, regulation_mark, set_name, set_full_name, set_number, 
          rule_box, tera_effect, weakness_type, weakness_value, 
          resistance_type, resistance_value, retreat_cost, raw_json)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
        ON CONFLICT (card_unique_id) DO NOTHING
      `, [
        cardUniqueId, card.name, card.img, card.card_type, card.stage,
        parseInt(card.hp) || null, parseInt(card.pokedex_number) || null,
        card.evolve_from ? card.evolve_from.join(', ') : null, card.regulation,
        card.set_name, card.set_full_name, card.number, card.rule_box,
        card.tera_effect, card.weakness?.type?.[0], card.weakness?.value,
        card.resistance?.type?.[0], card.resistance?.value, card.retreat,
        JSON.stringify(card)
      ]);
      
      if (card.types && Array.isArray(card.types)) {
        for (const type of card.types) {
          await client.query(
            'INSERT INTO card_types (card_unique_id, type_name) VALUES ($1, $2)',
            [cardUniqueId, type]
          );
        }
      }

      if (card.attacks && Array.isArray(card.attacks)) {
        for (let i = 0; i < card.attacks.length; i++) {
          const attack = card.attacks[i];
          const attackResult = await client.query(`
            INSERT INTO attacks (card_unique_id, name, damage, effect_description, position)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
          `, [cardUniqueId, attack.name, attack.damage, attack.effect, i + 1]);
          
          const attackId = attackResult.rows[0].id;
          
          if (attack.cost && Array.isArray(attack.cost)) {
            const energyCounts = {};
            for (const energy of attack.cost) {
              energyCounts[energy] = (energyCounts[energy] || 0) + 1;
            }
            for (const [energyType, count] of Object.entries(energyCounts)) {
              await client.query(
                'INSERT INTO attack_energy_costs (attack_id, energy_type, energy_count) VALUES ($1, $2, $3)',
                [attackId, energyType, count]
              );
            }
          }
        }
      }

      if (card.abilities && Array.isArray(card.abilities)) {
        for (const ability of card.abilities) {
          await client.query(
            'INSERT INTO card_abilities (card_unique_id, name, effect) VALUES ($1, $2, $3)',
            [cardUniqueId, ability.name, ability.effect]
          );
        }
      }

      if (card.tags && Array.isArray(card.tags)) {
        for (const tag of card.tags) {
          await client.query(
            'INSERT INTO card_tags (card_unique_id, tag_name) VALUES ($1, $2)',
            [cardUniqueId, tag]
          );
        }
      }

      await client.query('COMMIT');
      
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`❌ ${filePath}:`, err.message);
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(`讀取失敗: ${filePath}`);
  }
}

async function main() {
  try {
    console.log('🎮 開始匯入...\n');
    const setFolders = await fs.readdir(dataDir);
    let total = 0;
    const startTime = Date.now();
    
    for (const setFolder of setFolders) {
      const setPath = path.join(dataDir, setFolder);
      const stats = await fs.stat(setPath);
      
      if (stats.isDirectory()) {
        console.log(`📦 ${setFolder}`);
        const cardFiles = await fs.readdir(setPath);
        for (const cardFile of cardFiles) {
          if (path.extname(cardFile) === '.json') {
            total++;
            await processCard(path.join(setPath, cardFile), setFolder);
            if (total % 100 === 0) console.log(`   進度: ${total}`);
          }
        }
      }
    }
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`\n✨ 完成！共 ${total} 張卡牌，耗時 ${duration}秒\n`);
  } catch (err) {
    console.error('❌ 錯誤:', err);
  } finally {
    await pool.end();
  }
}

main();
