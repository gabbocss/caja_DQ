import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/proveedor_browser_service.dart';
import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/precio_producto.dart';
import '../../domain/entities/supermercado.dart';
import '../../domain/entities/unidad_medida.dart';
import '../../domain/precio_desde_texto.dart';
import '../providers/lista_compra_provider.dart';
import '../widgets/dialogo_revisar_producto.dart';

enum _ProveedorPrecio { metro, cc }

extension on _ProveedorPrecio {
  String get etiqueta => this == _ProveedorPrecio.metro ? 'Metro' : 'C&C';
}

/// Compra en desktop: edición producto + precios Metro / C&C.
class CompraDesktopPage extends StatefulWidget {
  const CompraDesktopPage({super.key});

  @override
  State<CompraDesktopPage> createState() => _CompraDesktopPageState();
}

class _CompraDesktopPageState extends State<CompraDesktopPage> {
  ItemListaCompra? _seleccionado;
  final _precioCtrl = TextEditingController();
  String? _estadoBrowser;
  bool _guardandoPrecio = false;
  Timer? _clipboardTimer;
  double? _precioDetectado;
  _ProveedorPrecio _proveedor = _ProveedorPrecio.metro;
  int? _editorItemId;
  bool _revisando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListaCompraProvider>().cargar();
    });
    _clipboardTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _intentarLeerPortapapeles();
    });
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _intentarLeerPortapapeles() async {
    if (!mounted || _seleccionado == null) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final precio = extraerPrecioEuros(data?.text);
      if (precio == null) return;
      if (_precioDetectado != null &&
          (_precioDetectado! - precio).abs() < 0.001) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _precioDetectado = precio;
        if (_precioCtrl.text.trim().isEmpty) {
          _precioCtrl.text = precio.toStringAsFixed(2);
        }
      });
    } catch (_) {}
  }

  void _seleccionar(ItemListaCompra item) {
    setState(() {
      _seleccionado = item;
      _editorItemId = item.id;
      _precioCtrl.clear();
      _precioDetectado = null;
      _estadoBrowser = null;
      _proveedor = item.tieneUrlMetro
          ? _ProveedorPrecio.metro
          : (item.tieneUrlCc ? _ProveedorPrecio.cc : _ProveedorPrecio.metro);
    });
  }

  Future<void> _abrirFicha(String urlRaw, _ProveedorPrecio proveedor) async {
    final url = urlRaw.trim();
    if (url.isEmpty) {
      setState(
        () => _estadoBrowser =
            'Sin enlace de ${proveedor.etiqueta}. Pégalo arriba.',
      );
      return;
    }
    setState(() => _estadoBrowser = 'Abriendo ${proveedor.etiqueta}…');
    final ok = await ProveedorBrowserService.abrir(url);
    if (!mounted) return;
    setState(() {
      _estadoBrowser = ok
          ? 'Ficha ${proveedor.etiqueta} abierta. Si pide login, entra una vez. '
              'Copia el precio o escríbelo abajo.'
          : 'No se pudo abrir el navegador. Revisa el enlace.';
    });
  }

  Future<Supermercado?> _asegurarProveedor(
    ListaCompraProvider provider,
    _ProveedorPrecio proveedor,
  ) {
    return proveedor == _ProveedorPrecio.metro
        ? provider.asegurarSupermercadoMetro()
        : provider.asegurarSupermercadoCc();
  }

  (Supermercado? metro, Supermercado? cc) _resolverSupers(
    ListaCompraProvider provider,
  ) {
    Supermercado? metro;
    Supermercado? cc;
    for (final s in provider.supermercados) {
      final n = s.nombre.toLowerCase();
      if (metro == null && n.contains('metro')) metro = s;
      if (cc == null) {
        final compact = n.replaceAll(' ', '');
        if (compact.contains('c&c') ||
            compact.contains('c+c') ||
            compact.contains('cash')) {
          cc = s;
        }
      }
    }
    return (metro, cc);
  }

  /// Recorre pendientes uno a uno y pide solo lo que falte.
  Future<void> _revisarTodos() async {
    final provider = context.read<ListaCompraProvider>();
    if (_revisando) return;

    setState(() => _revisando = true);
    await provider.cargar();
    if (!mounted) return;

    final pendientes = List<ItemListaCompra>.from(provider.pendientesCompra);
    if (pendientes.isEmpty) {
      setState(() => _revisando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos pendientes')),
      );
      return;
    }

    var guardados = 0;
    var saltados = 0;
    var completos = 0;

    for (var i = 0; i < pendientes.length; i++) {
      if (!mounted) return;

      // Datos frescos tras posibles guardados anteriores.
      final actual = provider.items.firstWhere(
        (x) => x.id == pendientes[i].id,
        orElse: () => pendientes[i],
      );
      final (metro, cc) = _resolverSupers(provider);
      final tieneMetro =
          metro != null && provider.precioEnSuper(actual.id, metro.id) != null;
      final tieneCc =
          cc != null && provider.precioEnSuper(actual.id, cc.id) != null;
      final faltantes = calcularFaltantes(
        item: actual,
        tienePrecioMetro: tieneMetro,
        tienePrecioCc: tieneCc,
      );

      if (!faltantes.hayAlgo) {
        completos++;
        continue;
      }

      _seleccionar(actual);
      // Deja pintar el panel derecho.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;

      final urlCc = actual.urlCc.trim().isNotEmpty
          ? actual.urlCc
          : null;
      final urlMetro = actual.urlMetro.trim().isNotEmpty
          ? actual.urlMetro
          : null;

      // Abre la ficha más útil para rellenar precios.
      if (urlCc != null && faltantes.precioCc) {
        await _abrirFicha(urlCc, _ProveedorPrecio.cc);
      } else if (urlMetro != null && faltantes.precioMetro) {
        await _abrirFicha(urlMetro, _ProveedorPrecio.metro);
      } else if (urlCc != null) {
        await _abrirFicha(urlCc, _ProveedorPrecio.cc);
      } else if (urlMetro != null) {
        await _abrirFicha(urlMetro, _ProveedorPrecio.metro);
      }
      if (!mounted) return;

      final paso = await mostrarDialogoRevisionProducto(
        context,
        item: actual,
        faltantes: faltantes,
        indice: i + 1,
        total: pendientes.length,
        onAbrirUrl: (url) async {
          final lower = url.toLowerCase();
          final proveedor = lower.contains('metro')
              ? _ProveedorPrecio.metro
              : _ProveedorPrecio.cc;
          await _abrirFicha(url, proveedor);
        },
      );

      if (!mounted) return;

      if (paso.resultado == ResultadoRevisionPaso.cancelado) {
        break;
      }
      if (paso.resultado == ResultadoRevisionPaso.saltado ||
          paso.datos == null) {
        saltados++;
        continue;
      }

      final ok = await _aplicarRevision(actual, paso.datos!);
      if (ok) {
        guardados++;
      } else {
        saltados++;
      }
    }

    if (!mounted) return;
    setState(() => _revisando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Revisión: $guardados guardados · $saltados saltados · '
          '$completos ya completos',
        ),
      ),
    );
  }

  Future<bool> _aplicarRevision(
    ItemListaCompra item,
    DatosRevisionProducto datos,
  ) async {
    final provider = context.read<ListaCompraProvider>();

    var unidadBase = datos.unidadBase ?? item.unidadBase;
    var contenidoUnidad = datos.contenidoUnidad ?? item.contenidoUnidad;
    if (unidadBase == UnidadBase.unidad) {
      contenidoUnidad = ContenidoUnidad.ud;
    }
    final contenidoText = datos.contenidoText;
    final contenido = contenidoText != null
        ? double.tryParse(contenidoText.trim().replaceAll(',', '.'))
        : item.contenidoCantidad;

    final exitoProd = await provider.editar(
      item,
      nombre: item.nombre,
      cantidad: item.cantidad,
      unidadBase: unidadBase,
      contenidoCantidad: contenido,
      clearContenido: contenidoText != null && contenidoText.trim().isEmpty,
      contenidoUnidad: contenidoUnidad,
      cantidadMinima: item.cantidadMinima,
      zona: item.zona,
      urlMetro: datos.urlMetro ?? item.urlMetro,
      urlCc: datos.urlCc ?? item.urlCc,
    );
    if (!exitoProd || !mounted) return false;

    final actualizado = provider.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );
    setState(() {
      _seleccionado = actualizado;
      _editorItemId = actualizado.id;
    });

    final cont = actualizado.contenidoCantidad;
    if (cont == null || cont <= 0) {
      // Sin contenido no se pueden guardar precios comparables.
      if (datos.precioMetro != null || datos.precioCc != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${actualizado.nombre}: guarda el contenido del envase '
              'para poder guardar precios.',
            ),
          ),
        );
      }
      return true;
    }

    if (datos.precioCc != null && datos.precioCc! > 0) {
      final superCc = await provider.asegurarSupermercadoCc();
      if (superCc != null) {
        await provider.guardarPrecio(
          producto: actualizado,
          supermercadoId: superCc.id,
          precioEnvase: datos.precioCc!,
          contenidoCantidad: cont,
          contenidoUnidad: actualizado.contenidoUnidad,
        );
      }
    }
    if (!mounted) return false;

    final refresco = provider.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => actualizado,
    );

    if (datos.precioMetro != null && datos.precioMetro! > 0) {
      final superMetro = await provider.asegurarSupermercadoMetro();
      if (superMetro != null) {
        await provider.guardarPrecio(
          producto: refresco,
          supermercadoId: superMetro.id,
          precioEnvase: datos.precioMetro!,
          contenidoCantidad: cont,
          contenidoUnidad: refresco.contenidoUnidad,
        );
      }
    }
    if (!mounted) return false;

    final finalItem = provider.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => refresco,
    );
    setState(() => _seleccionado = finalItem);
    return true;
  }

  Future<ItemListaCompra?> _guardarProducto({
    required ItemListaCompra item,
    required _DatosProductoForm datos,
    bool mostrarConfirmacion = true,
  }) async {
    final provider = context.read<ListaCompraProvider>();
    final contenido =
        double.tryParse(datos.contenidoText.trim().replaceAll(',', '.'));
    final minima = int.tryParse(datos.minimaText.trim()) ?? 1;
    var unidadContenido = datos.contenidoUnidad;
    if (datos.unidadBase == UnidadBase.unidad) {
      unidadContenido = ContenidoUnidad.ud;
    }

    final exito = await provider.editar(
      item,
      nombre: datos.nombre,
      cantidad: datos.cantidad,
      unidadBase: datos.unidadBase,
      contenidoCantidad: contenido,
      clearContenido: datos.contenidoText.trim().isEmpty,
      contenidoUnidad: unidadContenido,
      cantidadMinima: minima,
      zona: datos.zona,
      urlMetro: datos.urlMetro,
      urlCc: datos.urlCc,
    );
    if (!mounted) return null;
    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al guardar producto')),
      );
      return null;
    }

    final actualizado = provider.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );
    setState(() {
      _seleccionado = actualizado;
      _editorItemId = actualizado.id;
    });
    if (mostrarConfirmacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado')),
      );
    }
    return actualizado;
  }

  Future<void> _guardarPrecio({
    required ItemListaCompra item,
    required _DatosProductoForm datos,
    required _ProveedorPrecio proveedor,
  }) async {
    final precio = double.tryParse(_precioCtrl.text.trim().replaceAll(',', '.'));
    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un precio válido')),
      );
      return;
    }

    setState(() => _guardandoPrecio = true);
    final provider = context.read<ListaCompraProvider>();

    final guardado = await _guardarProducto(
      item: item,
      datos: datos,
      mostrarConfirmacion: false,
    );
    if (guardado == null) {
      if (mounted) setState(() => _guardandoPrecio = false);
      return;
    }
    if (!mounted) return;

    final contenido = guardado.contenidoCantidad;
    if (contenido == null || contenido <= 0) {
      setState(() => _guardandoPrecio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indica el contenido del envase (arriba) para guardar el precio.',
          ),
        ),
      );
      return;
    }

    final superP = await _asegurarProveedor(provider, proveedor);
    if (!mounted) return;
    if (superP == null) {
      setState(() => _guardandoPrecio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'No se pudo crear ${proveedor.etiqueta}',
          ),
        ),
      );
      return;
    }

    final exito = await provider.guardarPrecio(
      producto: guardado,
      supermercadoId: superP.id,
      precioEnvase: precio,
      contenidoCantidad: contenido,
      contenidoUnidad: guardado.contenidoUnidad,
    );
    if (!mounted) return;
    setState(() => _guardandoPrecio = false);
    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al guardar precio')),
      );
      return;
    }

    final porBase = calcularPrecioPorBase(
      precioEnvase: precio,
      contenidoCantidad: contenido,
      contenidoUnidad: guardado.contenidoUnidad,
      unidadBase: guardado.unidadBase,
    );
    final refreshed = provider.items.firstWhere(
      (i) => i.id == guardado.id,
      orElse: () => guardado,
    );
    setState(() => _seleccionado = refreshed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${proveedor.etiqueta}: ${precio.toStringAsFixed(2)} €'
          '${porBase != null ? ' · ${formatearPrecioPorBase(porBase, guardado.unidadBase)}' : ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Consumer<ListaCompraProvider>(
        builder: (context, provider, _) {
          final pendientes = provider.pendientesCompra;
          ItemListaCompra? sel = _seleccionado;
          if (sel != null) {
            final fromList = pendientes.where((i) => i.id == sel!.id);
            if (fromList.isNotEmpty) {
              sel = fromList.first;
            } else {
              final fromAll = provider.items.where((i) => i.id == sel!.id);
              sel = fromAll.isEmpty ? sel : fromAll.first;
            }
          }

          Supermercado? metro;
          Supermercado? cc;
          final supers = _resolverSupers(provider);
          metro = supers.$1;
          cc = supers.$2;

          PrecioProducto? precioMetro;
          PrecioProducto? precioCc;
          if (sel != null) {
            if (metro != null) {
              precioMetro = provider.precioEnSuper(sel.id, metro.id);
            }
            if (cc != null) {
              precioCc = provider.precioEnSuper(sel.id, cc.id);
            }
          }

          return Column(
            children: [
              _Header(
                cargando: provider.cargando,
                revisando: _revisando,
                onRefresh: () => provider.cargar(),
                onRevisarTodos: _revisarTodos,
              ),
              if (provider.error != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF5D1A1A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.cargar(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: _ListaPanel(
                        items: pendientes,
                        seleccionadoId: sel?.id,
                        preciosDe: provider.preciosDeProducto,
                        onSelect: _seleccionar,
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFF0F3460)),
                    Expanded(
                      child: sel == null
                          ? const Center(
                              child: Text(
                                'Selecciona un producto de la lista',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : _ProductoEditorPanel(
                              key: ValueKey(_editorItemId ?? sel.id),
                              item: sel,
                              precioCtrl: _precioCtrl,
                              precioDetectado: _precioDetectado,
                              estadoBrowser: _estadoBrowser,
                              guardandoPrecio: _guardandoPrecio,
                              proveedor: _proveedor,
                              precioMetro: precioMetro,
                              precioCc: precioCc,
                              onProveedorChanged: (p) {
                                setState(() => _proveedor = p);
                              },
                              onAbrirFicha: (url, p) => _abrirFicha(url, p),
                              onUsarDetectado: _precioDetectado == null
                                  ? null
                                  : () {
                                      _precioCtrl.text =
                                          _precioDetectado!.toStringAsFixed(2);
                                      setState(() {});
                                    },
                              onGuardarProducto: (datos) => _guardarProducto(
                                item: sel!,
                                datos: datos,
                              ),
                              onGuardarPrecio: (datos, proveedor) =>
                                  _guardarPrecio(
                                item: sel!,
                                datos: datos,
                                proveedor: proveedor,
                              ),
                              onMarcarComprado: () async {
                                await provider.marcarComprado(sel!, true);
                                if (!mounted) return;
                                setState(() => _seleccionado = null);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DatosProductoForm {
  final String nombre;
  final String cantidad;
  final String minimaText;
  final String contenidoText;
  final String urlMetro;
  final String urlCc;
  final UnidadBase unidadBase;
  final ContenidoUnidad contenidoUnidad;
  final ZonaListaCompra zona;

  const _DatosProductoForm({
    required this.nombre,
    required this.cantidad,
    required this.minimaText,
    required this.contenidoText,
    required this.urlMetro,
    required this.urlCc,
    required this.unidadBase,
    required this.contenidoUnidad,
    required this.zona,
  });
}

class _Header extends StatelessWidget {
  final bool cargando;
  final bool revisando;
  final VoidCallback onRefresh;
  final VoidCallback onRevisarTodos;

  const _Header({
    required this.cargando,
    required this.revisando,
    required this.onRefresh,
    required this.onRevisarTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Color(0xFFE94560)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Configura el producto y compara precios Metro / C&C',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: cargando || revisando ? null : onRevisarTodos,
            icon: revisando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check),
            label: Text(revisando ? 'Revisando…' : 'Revisar todos'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: cargando || revisando ? null : onRefresh,
            tooltip: 'Actualizar',
            icon: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ListaPanel extends StatelessWidget {
  final List<ItemListaCompra> items;
  final int? seleccionadoId;
  final List<PrecioProducto> Function(int productoId) preciosDe;
  final void Function(ItemListaCompra) onSelect;

  const _ListaPanel({
    required this.items,
    required this.seleccionadoId,
    required this.preciosDe,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay productos pendientes.\nMárcalos en «Hacer lista».',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = item.id == seleccionadoId;
        final precios = preciosDe(item.id);
        return Material(
          color: selected
              ? const Color(0xFFE94560).withValues(alpha: 0.15)
              : Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.tieneAlgunaUrl ? Icons.link : Icons.link_off,
                    size: 18,
                    color: item.tieneAlgunaUrl
                        ? const Color(0xFF00D9A5)
                        : Colors.white38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (item.cantidad.isNotEmpty)
                          Text(
                            item.cantidad,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          precios.isEmpty
                              ? 'Sin precios'
                              : '${precios.length} precio(s) guardado(s)',
                          style: TextStyle(
                            color: precios.isEmpty
                                ? Colors.orangeAccent
                                : const Color(0xFF66BB6A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductoEditorPanel extends StatefulWidget {
  final ItemListaCompra item;
  final TextEditingController precioCtrl;
  final double? precioDetectado;
  final String? estadoBrowser;
  final bool guardandoPrecio;
  final _ProveedorPrecio proveedor;
  final PrecioProducto? precioMetro;
  final PrecioProducto? precioCc;
  final ValueChanged<_ProveedorPrecio> onProveedorChanged;
  final Future<void> Function(String url, _ProveedorPrecio proveedor)
      onAbrirFicha;
  final VoidCallback? onUsarDetectado;
  final Future<ItemListaCompra?> Function(_DatosProductoForm datos)
      onGuardarProducto;
  final Future<void> Function(
    _DatosProductoForm datos,
    _ProveedorPrecio proveedor,
  ) onGuardarPrecio;
  final VoidCallback onMarcarComprado;

  const _ProductoEditorPanel({
    super.key,
    required this.item,
    required this.precioCtrl,
    required this.precioDetectado,
    required this.estadoBrowser,
    required this.guardandoPrecio,
    required this.proveedor,
    required this.precioMetro,
    required this.precioCc,
    required this.onProveedorChanged,
    required this.onAbrirFicha,
    required this.onUsarDetectado,
    required this.onGuardarProducto,
    required this.onGuardarPrecio,
    required this.onMarcarComprado,
  });

  @override
  State<_ProductoEditorPanel> createState() => _ProductoEditorPanelState();
}

class _ProductoEditorPanelState extends State<_ProductoEditorPanel> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _minimaCtrl;
  late final TextEditingController _contenidoCtrl;
  late final TextEditingController _urlMetroCtrl;
  late final TextEditingController _urlCcCtrl;
  late UnidadBase _unidadBase;
  late ContenidoUnidad _contenidoUnidad;
  late ZonaListaCompra _zona;
  bool _guardandoProducto = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nombreCtrl = TextEditingController(text: item.nombre);
    _cantidadCtrl = TextEditingController(text: item.cantidad);
    _minimaCtrl = TextEditingController(text: '${item.cantidadMinima}');
    _contenidoCtrl = TextEditingController(
      text: item.contenidoCantidad?.toString() ?? '',
    );
    _urlMetroCtrl = TextEditingController(text: item.urlMetro);
    _urlCcCtrl = TextEditingController(text: item.urlCc);
    _unidadBase = item.unidadBase;
    _contenidoUnidad = item.contenidoUnidad;
    _zona = item.zona;

    final urlInicial = widget.proveedor == _ProveedorPrecio.metro
        ? item.urlMetro
        : item.urlCc;
    if (urlInicial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAbrirFicha(urlInicial, widget.proveedor);
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _minimaCtrl.dispose();
    _contenidoCtrl.dispose();
    _urlMetroCtrl.dispose();
    _urlCcCtrl.dispose();
    super.dispose();
  }

  _DatosProductoForm _datos() => _DatosProductoForm(
        nombre: _nombreCtrl.text,
        cantidad: _cantidadCtrl.text,
        minimaText: _minimaCtrl.text,
        contenidoText: _contenidoCtrl.text,
        urlMetro: _urlMetroCtrl.text,
        urlCc: _urlCcCtrl.text,
        unidadBase: _unidadBase,
        contenidoUnidad: _contenidoUnidad,
        zona: _zona,
      );

  String get _urlActiva => widget.proveedor == _ProveedorPrecio.metro
      ? _urlMetroCtrl.text
      : _urlCcCtrl.text;

  InputDecoration _deco(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      filled: true,
      fillColor: const Color(0xFF16213E),
    );
  }

  ButtonStyle _segStyle(Color selectedBg) => ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black87;
          return Colors.white70;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return selectedBg;
          return const Color(0xFF0D0D0D);
        }),
      );

  String _textoPrecio(PrecioProducto? p, ItemListaCompra item) {
    if (p == null) return '—';
    return formatearPrecioCompleto(
      precioEnvase: p.precioEnvase,
      precioPorBase: p.precioPorBase,
      unidadBase: item.unidadBase,
    );
  }

  Widget _chipComparativa({
    required String label,
    required PrecioProducto? precio,
    required bool esMejor,
  }) {
    final color = precio == null
        ? Colors.white38
        : (esMejor ? const Color(0xFF00D9A5) : Colors.white70);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: esMejor && precio != null
                ? const Color(0xFF00D9A5)
                : const Color(0xFF0F3460),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label + (esMejor && precio != null ? ' · mejor' : ''),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _textoPrecio(precio, widget.item),
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pm = widget.precioMetro;
    final pc = widget.precioCc;
    final mejorMetro = pm != null &&
        (pc == null || pm.precioPorBase <= pc.precioPorBase);
    final mejorCc = pc != null &&
        (pm == null || pc.precioPorBase < pm.precioPorBase);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco('Nombre'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Zona',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ZonaListaCompra>(
                  segments: const [
                    ButtonSegment(
                      value: ZonaListaCompra.cocina,
                      label: Text('Cocina'),
                      icon: Icon(Icons.kitchen_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ZonaListaCompra.sala,
                      label: Text('Sala'),
                      icon: Icon(Icons.table_restaurant_outlined, size: 16),
                    ),
                  ],
                  selected: {_zona},
                  onSelectionChanged: (sel) {
                    setState(() => _zona = sel.first);
                  },
                  style: _segStyle(const Color(0xFFFFB74D)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cantidadCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco('Nota cantidad (opcional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _minimaCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    'Cantidad mínima a comprar',
                    hint: '1, 2, 3…',
                    helper: 'Envases/unidades que sueles comprar',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Se compra / compara por',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<UnidadBase>(
                  segments: const [
                    ButtonSegment(
                      value: UnidadBase.kilo,
                      label: Text('Kilo'),
                      icon: Icon(Icons.scale, size: 16),
                    ),
                    ButtonSegment(
                      value: UnidadBase.litro,
                      label: Text('Litro'),
                      icon: Icon(Icons.water_drop_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: UnidadBase.unidad,
                      label: Text('Unidad'),
                      icon: Icon(Icons.tag, size: 16),
                    ),
                  ],
                  selected: {_unidadBase},
                  onSelectionChanged: (sel) {
                    setState(() {
                      _unidadBase = sel.first;
                      _contenidoUnidad =
                          ContenidoUnidad.paraBase(_unidadBase).first;
                    });
                  },
                  style: _segStyle(const Color(0xFFFFB74D)),
                ),
                const SizedBox(height: 12),
                if (_unidadBase == UnidadBase.unidad)
                  TextField(
                    controller: _contenidoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco(
                      'Unidades por envase (opcional)',
                      hint: '1',
                    ),
                  )
                else ...[
                  TextField(
                    controller: _contenidoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco(
                      _unidadBase == UnidadBase.litro
                          ? 'Tamaño del envase'
                          : 'Peso del envase',
                      hint: _unidadBase == UnidadBase.litro ? '750' : '500',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Medida del envase',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ContenidoUnidad>(
                    segments: ContenidoUnidad.paraBase(_unidadBase)
                        .map(
                          (u) => ButtonSegment(
                            value: u,
                            label: Text(u.etiquetaLarga),
                          ),
                        )
                        .toList(),
                    selected: {
                      ContenidoUnidad.paraBase(_unidadBase)
                              .contains(_contenidoUnidad)
                          ? _contenidoUnidad
                          : ContenidoUnidad.paraBase(_unidadBase).first,
                    },
                    onSelectionChanged: (sel) {
                      setState(() => _contenidoUnidad = sel.first);
                    },
                    style: _segStyle(const Color(0xFF4FC3F7)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _unidadBase == UnidadBase.litro
                      ? 'Los precios se compararán en €/L'
                      : _unidadBase == UnidadBase.kilo
                          ? 'Los precios se compararán en €/kg'
                          : 'Los precios se compararán en €/unidad',
                  style: const TextStyle(
                    color: Color(0xFF66BB6A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF0F3460)),
                const SizedBox(height: 12),
                const Text(
                  'Precios Metro / C&C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chipComparativa(
                      label: 'Metro',
                      precio: pm,
                      esMejor: mejorMetro,
                    ),
                    const SizedBox(width: 10),
                    _chipComparativa(
                      label: 'C&C',
                      precio: pc,
                      esMejor: mejorCc,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Guardar precio de',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_ProveedorPrecio>(
                  segments: const [
                    ButtonSegment(
                      value: _ProveedorPrecio.metro,
                      label: Text('Metro'),
                      icon: Icon(Icons.storefront_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: _ProveedorPrecio.cc,
                      label: Text('C&C'),
                      icon: Icon(Icons.local_convenience_store_outlined, size: 16),
                    ),
                  ],
                  selected: {widget.proveedor},
                  onSelectionChanged: (sel) {
                    widget.onProveedorChanged(sel.first);
                  },
                  style: _segStyle(const Color(0xFFE94560)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlMetroCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    'URL Metro',
                    hint: 'https://prodotti.metro.it/...',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlCcCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    'URL C&C',
                    hint: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onAbrirFicha(
                        _urlActiva,
                        widget.proveedor,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('Abrir ${widget.proveedor.etiqueta}'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onMarcarComprado,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar comprado'),
                    ),
                  ],
                ),
                if (widget.estadoBrowser != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.estadoBrowser!,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (widget.precioDetectado != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          'Detectado en portapapeles: '
                          '${widget.precioDetectado!.toStringAsFixed(2)} €',
                          style: const TextStyle(color: Color(0xFF00D9A5)),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: widget.onUsarDetectado,
                          child: const Text('Usar'),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: widget.precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: _deco(
                    'Precio envase ${widget.proveedor.etiqueta} (€)',
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            border: Border(top: BorderSide(color: Color(0xFF0F3460))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardandoProducto || widget.guardandoPrecio
                      ? null
                      : () async {
                          setState(() => _guardandoProducto = true);
                          await widget.onGuardarProducto(_datos());
                          if (mounted) {
                            setState(() => _guardandoProducto = false);
                          }
                        },
                  child: _guardandoProducto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar producto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _guardandoProducto || widget.guardandoPrecio
                      ? null
                      : () => widget.onGuardarPrecio(
                            _datos(),
                            widget.proveedor,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: widget.guardandoPrecio
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Guardar precio ${widget.proveedor.etiqueta}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
