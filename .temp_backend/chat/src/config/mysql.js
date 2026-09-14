import mysql from 'mysql2/promise';
import { config } from './env.js';

let pool = null;

export function getMysqlPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: config.mysql.host,
      user: config.mysql.user,
      password: config.mysql.password,
      database: config.mysql.database,
      port: config.mysql.port,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10000
    });
  }
  return pool;
}

/**
 * Execute a SQL query safely against MySQL.
 * If the configured database name doesn't exist, try fallback database names.
 */
export async function queryMysql(sql, params = []) {
  try {
    const currentPool = getMysqlPool();
    const [rows] = await currentPool.query(sql, params);
    return rows;
  } catch (err) {
    // If unknown database error, try fallback database names (e.g. fairbiz, gamecrm)
    if (err.code === 'ER_BAD_DB_ERROR') {
      const fallbacks = ['fairbiz', 'gamecrm', 'telewiz_ofcmanage_db'].filter(d => d !== config.mysql.database);
      for (const fbDb of fallbacks) {
        try {
          const tempPool = mysql.createPool({
            ...config.mysql,
            database: fbDb,
            connectionLimit: 5
          });
          const [rows] = await tempPool.query(sql, params);
          pool = tempPool; // Switch to the active working database pool
          console.log(`[MySQL] Switched active database to: ${fbDb}`);
          return rows;
        } catch (_) {}
      }
    }
    console.warn('[MySQL Query Warning]:', err.message);
    throw err;
  }
}
