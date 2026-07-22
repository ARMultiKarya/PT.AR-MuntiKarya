/**
 * PT AR MULTI KARYA - MySQL REST API Gateway (Node.js Express Version)
 * Deskripsi: Gateway API untuk menghubungkan frontend index.html dengan database MySQL.
 * Cara Menjalankan:
 * 1. Jalankan `npm install express mysql2 cors`
 * 2. Jalankan `node server.js`
 */

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// === DATABASE CONFIGURATION ===
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'pt_ar_multikarya_db'
};

let pool;

async function connectDB() {
  try {
    pool = mysql.createPool(dbConfig);
    console.log('MySQL Connection Pool created successfully.');
  } catch (err) {
    console.error('Database connection failed:', err);
    process.exit(1);
  }
}
connectDB();

// Helper to parse readBy for chat messages
function parseReadBy(readByVal) {
  if (!readByVal) return [];
  if (Array.isArray(readByVal)) return readByVal;
  try {
    return JSON.parse(readByVal);
  } catch (e) {
    return String(readByVal).split(',');
  }
}

// REST ENDPOINTS
app.get('/api', async (req, res) => {
  const { store, id } = req.query;
  if (!store) {
    return res.status(400).json({ error: 'Store parameter is required' });
  }

  try {
    if (id) {
      const [rows] = await pool.query('SELECT * FROM ?? WHERE id = ?', [store, id]);
      const row = rows[0];
      if (row) {
        if (store === 'chat_messages' && row.readBy) {
          row.readBy = parseReadBy(row.readBy);
        }
        // Merge relational items
        if (store === 'po') {
          const [items] = await pool.query('SELECT * FROM po_items WHERE poId = ?', [row.id]);
          row.items = items;
        } else if (store === 'bukti_pembelian') {
          const [items] = await pool.query('SELECT * FROM bukti_pembelian_items WHERE buktiPembelianId = ?', [row.id]);
          row.items = items.map(it => ({
            barangId: Number(it.barangId),
            qty: Number(it.qty),
            unitCost: Number(it.unitCost)
          }));
        } else if (store === 'invoice_jual') {
          const [items] = await pool.query('SELECT * FROM invoice_jual_items WHERE invoiceJualId = ?', [row.id]);
          row.items = items;
        }
      }
      res.json(row || null);
    } else {
      const [rows] = await pool.query('SELECT * FROM ??', [store]);
      
      if (store === 'chat_messages') {
        rows.forEach(row => {
          if (row.readBy) row.readBy = parseReadBy(row.readBy);
        });
      } else if (store === 'po') {
        const [allItems] = await pool.query('SELECT * FROM po_items');
        rows.forEach(row => {
          row.items = allItems.filter(it => it.poId == row.id);
        });
      } else if (store === 'bukti_pembelian') {
        const [allItems] = await pool.query('SELECT * FROM bukti_pembelian_items');
        rows.forEach(row => {
          row.items = allItems.filter(it => it.buktiPembelianId == row.id).map(it => ({
            barangId: Number(it.barangId),
            qty: Number(it.qty),
            unitCost: Number(it.unitCost)
          }));
        });
      } else if (store === 'invoice_jual') {
        const [allItems] = await pool.query('SELECT * FROM invoice_jual_items');
        rows.forEach(row => {
          row.items = allItems.filter(it => it.invoiceJualId == row.id);
        });
      }
      res.json(rows);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api', async (req, res) => {
  const { store } = req.query;
  if (!store) {
    return res.status(400).json({ error: 'Store parameter is required' });
  }

  const { items, ...mainData } = req.body;

  // Handle readBy formatting for chat
  if (store === 'chat_messages' && mainData.readBy && Array.isArray(mainData.readBy)) {
    mainData.readBy = JSON.stringify(mainData.readBy);
  }

  try {
    let finalId = mainData.id;

    if (finalId && store !== 'settings') {
      // UPDATE
      await pool.query('UPDATE ?? SET ? WHERE id = ?', [store, mainData, finalId]);
    } else {
      // INSERT or REPLACE settings
      if (store === 'settings') {
        await pool.query('DELETE FROM settings WHERE id = ?', [mainData.id]);
      }
      const [result] = await pool.query('INSERT INTO ?? SET ?', [store, mainData]);
      finalId = store === 'settings' ? mainData.id : result.insertId;
    }

    // Update relational items
    if (store === 'po' && items) {
      await pool.query('DELETE FROM po_items WHERE poId = ?', [finalId]);
      for (const it of items) {
        await pool.query('INSERT INTO po_items (poId, barangId, qty, price, total) VALUES (?, ?, ?, ?, ?)', [
          finalId, Number(it.barangId), Number(it.qty), Number(it.price), Number(it.total)
        ]);
      }
    } else if (store === 'bukti_pembelian' && items) {
      await pool.query('DELETE FROM bukti_pembelian_items WHERE buktiPembelianId = ?', [finalId]);
      for (const it of items) {
        await pool.query('INSERT INTO bukti_pembelian_items (buktiPembelianId, barangId, qty, unitCost) VALUES (?, ?, ?, ?)', [
          finalId, Number(it.barangId), Number(it.qty), Number(it.unitCost)
        ]);
      }
    } else if (store === 'invoice_jual' && items) {
      await pool.query('DELETE FROM invoice_jual_items WHERE invoiceJualId = ?', [finalId]);
      for (const it of items) {
        await pool.query('INSERT INTO invoice_jual_items (invoiceJualId, barangId, qty, price, total, hpp) VALUES (?, ?, ?, ?, ?, ?)', [
          finalId, Number(it.barangId), Number(it.qty), Number(it.price), Number(it.total), Number(it.hpp || 0)
        ]);
      }
    }

    res.json({ success: true, id: finalId });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api', async (req, res) => {
  const { store, id } = req.query;
  if (!store || !id) {
    return res.status(400).json({ error: 'Store and id parameters are required' });
  }

  try {
    // Cascading deletes on item tables
    if (store === 'po') {
      await pool.query('DELETE FROM po_items WHERE poId = ?', [id]);
    } else if (store === 'bukti_pembelian') {
      await pool.query('DELETE FROM bukti_pembelian_items WHERE buktiPembelianId = ?', [id]);
    } else if (store === 'invoice_jual') {
      await pool.query('DELETE FROM invoice_jual_items WHERE invoiceJualId = ?', [id]);
    }

    await pool.query('DELETE FROM ?? WHERE id = ?', [store, id]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`PT AR Multi Karya MySQL API Server listening on port ${PORT}`);
  console.log(`Endpoint URL: http://localhost:${PORT}/api`);
});
