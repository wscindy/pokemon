import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  user: 'liweixuan',
  host: 'localhost',
  database: 'pokemon_tcg_development',
  password: 'postgres123',
  port: 5432,
});

async function parseAllCards() {
  const client = await pool.connect();
  
  try {
    console.log('🎮 開始解析 raw_json...\n');
    
    // 獲取所有卡牌
    const result = await client.query('SELECT id, card_unique_id, raw_json FROM cards ORDER BY id');
    const cards = result.rows;
    
    let processedCount = 0;
    let errorCount = 0;
    
    for (const card of cards) {
      try {
        const cardData = card.raw_json;
        const cardUniqueId = card.card_unique_id;
        
        // 插入屬性 (card_types)
        if (cardData.types && Array.isArray(cardData.types)) {
          for (const type of cardData.types) {
            await client.query(
              'INSERT INTO card_types (card_unique_id, type_name) VALUES ($1, $2) ON CONFLICT DO NOTHING',
              [cardUniqueId, type]
            );
          }
        }
        
        // 插入招式 (attacks)
        if (cardData.attacks && Array.isArray(cardData.attacks)) {
          for (let i = 0; i < cardData.attacks.length; i++) {
            const attack = cardData.attacks[i];
            
            const attackResult = await client.query(`
              INSERT INTO attacks (card_unique_id, name, damage, effect_description, position)
              VALUES ($1, $2, $3, $4, $5)
              ON CONFLICT DO NOTHING
              RETURNING id
            `, [cardUniqueId, attack.name, attack.damage, attack.effect, i + 1]);
            
            // 只在新插入時才插入能量消耗
            if (attackResult.rows.length > 0) {
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
        }
        
        // 插入特性 (card_abilities)
        if (cardData.abilities && Array.isArray(cardData.abilities)) {
          for (const ability of cardData.abilities) {
            await client.query(
              'INSERT INTO card_abilities (card_unique_id, name, effect) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING',
              [cardUniqueId, ability.name, ability.effect]
            );
          }
        }
        
        // 插入標籤 (card_tags)
        if (cardData.tags && Array.isArray(cardData.tags)) {
          for (const tag of cardData.tags) {
            await client.query(
              'INSERT INTO card_tags (card_unique_id, tag_name) VALUES ($1, $2) ON CONFLICT DO NOTHING',
              [cardUniqueId, tag]
            );
          }
        }
        
        processedCount++;
        if (processedCount % 500 === 0) {
          console.log(`✅ 進度: ${processedCount}/${cards.length}`);
        }
        
      } catch (err) {
        errorCount++;
        console.error(`❌ 卡牌 ${card.card_unique_id}:`, err.message);
      }
    }
    
    console.log(`\n✨ 完成！處理了 ${processedCount} 張卡牌`);
    if (errorCount > 0) {
      console.log(`⚠️  出現 ${errorCount} 個錯誤`);
    }
    
  } catch (err) {
    console.error('❌ 發生錯誤:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

parseAllCards();
