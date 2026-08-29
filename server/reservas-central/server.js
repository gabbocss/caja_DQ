/**
 * API de reservas 24/7 — compatible con programa_caja (LocalServer / ApiClient).
 * Sin Flutter ni UI. Pensado para PM2 en VPS.
 */
const http = require('http');
const { URL } = require('url');
const store = require('./store');

const PORT = Number(process.env.PORT || 8888);
const HOST = process.env.HOST || '0.0.0.0';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept',
};

function send(res, status, body, extraHeaders = {}) {
  const payload =
    typeof body === 'string' ? body : JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    ...CORS,
    ...extraHeaders,
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 2 * 1024 * 1024) {
        reject(new Error('Body demasiado grande'));
        req.destroy();
      }
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

function healthPayload() {
  return {
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'programa-caja-reservas-central',
  };
}

function apiIndexPayload() {
  return {
    mensaje: 'API del Sistema de Restaurante',
    version: '1.0.0',
    endpoints: {
      reservas: '/api/reservas',
      reservasMarcarSincronizadas: '/api/reservas/marcar-sincronizadas',
      productos: '/api/productos',
      health: '/health',
      healthApi: '/api/health',
    },
  };
}

async function handle(req, res) {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const path = url.pathname;
  const method = req.method;

  if (method === 'OPTIONS') {
    res.writeHead(204, CORS);
    res.end();
    return;
  }

  try {
    if (method === 'GET' && (path === '/health' || path === '/api/health')) {
      send(res, 200, healthPayload());
      return;
    }

    if (method === 'GET' && path === '/api') {
      send(res, 200, apiIndexPayload());
      return;
    }

    if (method === 'GET' && path === '/api/reservas') {
      const incluye = url.searchParams.get('incluye');
      const lista =
        incluye === 'sincronizadas'
          ? store.getPendientesEditables()
          : store.getPendientes();
      send(res, 200, lista);
      return;
    }

    if (method === 'GET' && path === '/api/productos') {
      send(res, 200, store.readProductos());
      return;
    }

    if (method === 'POST' && path === '/api/productos') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '[]');
      const guardados = store.replaceProductos(data);
      send(res, 200, guardados);
      return;
    }

    if (method === 'POST' && path === '/api/reservas') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const guardada = store.upsertReserva(data);
      send(res, 200, guardada);
      return;
    }

    if (method === 'POST' && path === '/api/reservas/marcar-sincronizadas') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const ids = data.ids != null ? data.ids : [];
      const resultado = store.marcarSincronizadas(ids);
      send(res, 200, resultado);
      return;
    }

    const estadoMatch = path.match(/^\/api\/reservas\/(\d+)\/estado$/);
    if (method === 'PUT' && estadoMatch) {
      const id = estadoMatch[1];
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const actualizada = store.updateEstado(
        id,
        data.estado || 'pendiente',
        data.mesaAsignada,
      );
      if (!actualizada) {
        send(res, 404, { error: 'Reserva no encontrada' });
        return;
      }
      send(res, 200, actualizada);
      return;
    }

    send(res, 404, { error: 'Not Found', path });
  } catch (e) {
    console.error(e);
    send(res, 500, { error: String(e.message || e) });
  }
}

const server = http.createServer((req, res) => {
  handle(req, res);
});

server.listen(PORT, HOST, () => {
  console.log(
    `Reservas central: http://${HOST === '0.0.0.0' ? 'localhost' : HOST}:${PORT}`,
  );
  console.log(`  GET  /api`);
  console.log(`  GET  /api/reservas`);
  console.log(`  POST /api/reservas/marcar-sincronizadas`);
  console.log(`  GET/POST /api/productos`);
  console.log(`  Datos: ${store.DATA_FILE}, ${store.PRODUCTOS_FILE}`);
});
