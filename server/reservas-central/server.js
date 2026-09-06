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
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
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
      listaCompra: '/api/lista-compra',
      listaCompraVaciarCompra: '/api/lista-compra/vaciar-compra',
      listaCompraReordenar: '/api/lista-compra/reordenar',
      listaCompraPrecios: '/api/lista-compra/precios',
      supermercados: '/api/supermercados',
      supermercadosReordenar: '/api/supermercados/reordenar',
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

    if (method === 'GET' && path === '/api/lista-compra') {
      send(res, 200, store.getListaCompra());
      return;
    }

    if (method === 'POST' && path === '/api/lista-compra') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const guardado = store.upsertItemListaCompra(data);
      send(res, 200, guardado);
      return;
    }

    // Resetea flags de compra; NUNCA borra el catálogo.
    if (method === 'POST' && path === '/api/lista-compra/vaciar-compra') {
      send(res, 200, store.vaciarCompraListaCompra());
      return;
    }

    if (method === 'POST' && path === '/api/lista-compra/reordenar') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const ids = data.ids != null ? data.ids : [];
      send(res, 200, store.reordenarListaCompra(ids));
      return;
    }

    if (method === 'GET' && path === '/api/lista-compra/precios') {
      send(
        res,
        200,
        store.getPreciosListaCompra({
          productoId: url.searchParams.get('productoId'),
          supermercadoId: url.searchParams.get('supermercadoId'),
        }),
      );
      return;
    }

    if (method === 'POST' && path === '/api/lista-compra/precios') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      send(res, 200, store.upsertPrecioListaCompra(data));
      return;
    }

    const precioMatch = path.match(/^\/api\/lista-compra\/precios\/(\d+)$/);
    if (method === 'DELETE' && precioMatch) {
      const ok = store.deletePrecioListaCompra(precioMatch[1]);
      if (!ok) {
        send(res, 404, { error: 'Precio no encontrado' });
        return;
      }
      send(res, 200, { ok: true, id: Number(precioMatch[1]) });
      return;
    }

    const listaCompraMatch = path.match(/^\/api\/lista-compra\/(\d+)$/);
    if (listaCompraMatch) {
      const id = listaCompraMatch[1];
      if (method === 'PUT') {
        const raw = await readBody(req);
        const data = JSON.parse(raw || '{}');
        const actualizado = store.updateItemListaCompra(id, data);
        if (!actualizado) {
          send(res, 404, { error: 'Ítem no encontrado' });
          return;
        }
        send(res, 200, actualizado);
        return;
      }
      if (method === 'DELETE') {
        const ok = store.deleteItemListaCompra(id);
        if (!ok) {
          send(res, 404, { error: 'Ítem no encontrado' });
          return;
        }
        send(res, 200, { ok: true, id: Number(id) });
        return;
      }
    }

    if (method === 'GET' && path === '/api/supermercados') {
      send(res, 200, store.getSupermercados());
      return;
    }

    if (method === 'POST' && path === '/api/supermercados') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      send(res, 200, store.upsertSupermercado(data));
      return;
    }

    if (method === 'POST' && path === '/api/supermercados/reordenar') {
      const raw = await readBody(req);
      const data = JSON.parse(raw || '{}');
      const ids = data.ids != null ? data.ids : [];
      send(res, 200, store.reordenarSupermercados(ids));
      return;
    }

    const supermercadoMatch = path.match(/^\/api\/supermercados\/(\d+)$/);
    if (supermercadoMatch) {
      const id = supermercadoMatch[1];
      if (method === 'PUT') {
        const raw = await readBody(req);
        const data = JSON.parse(raw || '{}');
        const actualizado = store.updateSupermercado(id, data);
        if (!actualizado) {
          send(res, 404, { error: 'Supermercado no encontrado' });
          return;
        }
        send(res, 200, actualizado);
        return;
      }
      if (method === 'DELETE') {
        const ok = store.deleteSupermercado(id);
        if (!ok) {
          send(res, 404, { error: 'Supermercado no encontrado' });
          return;
        }
        send(res, 200, { ok: true, id: Number(id) });
        return;
      }
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
  console.log(`  GET/POST /api/lista-compra`);
  console.log(`  POST /api/lista-compra/vaciar-compra`);
  console.log(`  POST /api/lista-compra/reordenar`);
  console.log(`  GET/POST /api/lista-compra/precios`);
  console.log(`  PUT/DELETE /api/lista-compra/:id`);
  console.log(`  GET/POST /api/supermercados`);
  console.log(`  POST /api/supermercados/reordenar`);
  console.log(`  PUT/DELETE /api/supermercados/:id`);
  console.log(
    `  Datos: ${store.DATA_FILE}, ${store.PRODUCTOS_FILE}, ${store.LISTA_COMPRA_FILE}, ${store.SUPERMERCADOS_FILE}, ${store.PRECIOS_LISTA_COMPRA_FILE}`,
  );
});
