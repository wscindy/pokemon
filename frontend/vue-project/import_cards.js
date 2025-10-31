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
  password: 'postgres123',
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
      console.log(`✅ ${card.name}`);
      
    } catch (err) {
      console.error(`❌ ${cardUniqueId}:`, err.message);
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(`讀取失敗`);
  }
}

async function main() {
  try {
    console.log('🎮 開始匯入卡牌資料...\n');
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
    console.log(`\n✨ 完成！共 ${total} 張卡牌已匯入 cards 表，耗時 ${duration}秒\n`);
  } catch (err) {
    console.error('❌ 錯誤:', err);
  } finally {
    await pool.end();
  }
}

main();
