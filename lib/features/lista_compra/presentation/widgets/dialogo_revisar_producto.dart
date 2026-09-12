import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/unidad_medida.dart';
import '../../domain/precio_desde_texto.dart';

/// Qué falta completar en un producto de la lista de compra.
class FaltantesProducto {
  final bool contenido;
  final bool urlMetro;
  final bool urlCc;
  final bool precioMetro;
  final bool precioCc;

  const FaltantesProducto({
    required this.contenido,
    required this.urlMetro,
    required this.urlCc,
    required this.precioMetro,
    required this.precioCc,
  });

  bool get hayAlgo =>
      contenido || urlMetro || urlCc || precioMetro || precioCc;

  List<String> get etiquetas {
    return [
      if (contenido) 'contenido del envase',
      if (urlMetro) 'URL Metro',
      if (urlCc) 'URL C&C',
      if (precioMetro) 'precio Metro',
      if (precioCc) 'precio C&C',
    ];
  }
}

FaltantesProducto calcularFaltantes({
  required ItemListaCompra item,
  required bool tienePrecioMetro,
  required bool tienePrecioCc,
}) {
  final sinContenido =
      item.contenidoCantidad == null || item.contenidoCantidad! <= 0;
  return FaltantesProducto(
    contenido: sinContenido,
    urlMetro: !item.tieneUrlMetro,
    urlCc: !item.tieneUrlCc,
    precioMetro: !tienePrecioMetro,
    precioCc: !tienePrecioCc,
  );
}

enum ResultadoRevisionPaso { guardado, saltado, cancelado }

/// Datos rellenados en un paso del asistente «Revisar todos».
class DatosRevisionProducto {
  final String? contenidoText;
  final UnidadBase? unidadBase;
  final ContenidoUnidad? contenidoUnidad;
  final String? urlMetro;
  final String? urlCc;
  final double? precioMetro;
  final double? precioCc;

  const DatosRevisionProducto({
    this.contenidoText,
    this.unidadBase,
    this.contenidoUnidad,
    this.urlMetro,
    this.urlCc,
    this.precioMetro,
    this.precioCc,
  });
}

/// Diálogo para completar lo que falta de un producto en el asistente.
  Future<({ResultadoRevisionPaso resultado, DatosRevisionProducto? datos})>
    mostrarDialogoRevisionProducto(
  BuildContext context, {
  required ItemListaCompra item,
  required FaltantesProducto faltantes,
  required int indice,
  required int total,
  required Future<void> Function(String url) onAbrirUrl,
}) async {
  final r = await showDialog<
      ({ResultadoRevisionPaso resultado, DatosRevisionProducto? datos})>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DialogoRevisionProducto(
      item: item,
      faltantes: faltantes,
      indice: indice,
      total: total,
      onAbrirUrl: onAbrirUrl,
    ),
  );
  return r ??
      (
        resultado: ResultadoRevisionPaso.cancelado,
        datos: null,
      );
}

class _DialogoRevisionProducto extends StatefulWidget {
  final ItemListaCompra item;
  final FaltantesProducto faltantes;
  final int indice;
  final int total;
  final Future<void> Function(String url) onAbrirUrl;

  const _DialogoRevisionProducto({
    required this.item,
    required this.faltantes,
    required this.indice,
    required this.total,
    required this.onAbrirUrl,
  });

  @override
  State<_DialogoRevisionProducto> createState() =>
      _DialogoRevisionProductoState();
}

class _DialogoRevisionProductoState extends State<_DialogoRevisionProducto> {
  late final TextEditingController _contenidoCtrl;
  late final TextEditingController _urlMetroCtrl;
  late final TextEditingController _urlCcCtrl;
  late final TextEditingController _precioMetroCtrl;
  late final TextEditingController _precioCcCtrl;
  late UnidadBase _unidadBase;
  late ContenidoUnidad _contenidoUnidad;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _contenidoCtrl = TextEditingController(
      text: item.contenidoCantidad?.toString() ?? '',
    );
    _urlMetroCtrl = TextEditingController(text: item.urlMetro);
    _urlCcCtrl = TextEditingController(text: item.urlCc);
    _precioMetroCtrl = TextEditingController();
    _precioCcCtrl = TextEditingController();
    _unidadBase = item.unidadBase;
    _contenidoUnidad = item.contenidoUnidad;
  }

  @override
  void dispose() {
    _contenidoCtrl.dispose();
    _urlMetroCtrl.dispose();
    _urlCcCtrl.dispose();
    _precioMetroCtrl.dispose();
    _precioCcCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0D0D0D),
    );
  }

  void _pegarPortapapelesEn(TextEditingController ctrl) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final precio = extraerPrecioEuros(data?.text);
      if (precio != null) {
        ctrl.text = precio.toStringAsFixed(2);
        setState(() {});
      } else if (data?.text != null && data!.text!.trim().isNotEmpty) {
        ctrl.text = data.text!.trim();
        setState(() {});
      }
    } catch (_) {}
  }

  void _confirmar() {
    final f = widget.faltantes;
    Navigator.pop(context, (
      resultado: ResultadoRevisionPaso.guardado,
      datos: DatosRevisionProducto(
        contenidoText: f.contenido ? _contenidoCtrl.text : null,
        unidadBase: f.contenido ? _unidadBase : null,
        contenidoUnidad: f.contenido ? _contenidoUnidad : null,
        urlMetro: f.urlMetro ? _urlMetroCtrl.text : null,
        urlCc: f.urlCc ? _urlCcCtrl.text : null,
        precioMetro: f.precioMetro
            ? double.tryParse(
                _precioMetroCtrl.text.trim().replaceAll(',', '.'),
              )
            : null,
        precioCc: f.precioCc
            ? double.tryParse(
                _precioCcCtrl.text.trim().replaceAll(',', '.'),
              )
            : null,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.faltantes;
    final item = widget.item;

    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text(
        'Revisar ${widget.indice}/${widget.total}: ${item.nombre}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Falta: ${f.etiquetas.join(', ')}',
                style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final u = _urlCcCtrl.text.trim().isNotEmpty
                          ? _urlCcCtrl.text.trim()
                          : widget.item.urlCc.trim();
                      if (u.isEmpty) return;
                      widget.onAbrirUrl(u);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Abrir C&C'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final u = _urlMetroCtrl.text.trim().isNotEmpty
                          ? _urlMetroCtrl.text.trim()
                          : widget.item.urlMetro.trim();
                      if (u.isEmpty) return;
                      widget.onAbrirUrl(u);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Abrir Metro'),
                  ),
                ],
              ),
              if (f.contenido) ...[
                const SizedBox(height: 16),
                const Text(
                  'Contenido del envase',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<UnidadBase>(
                  segments: const [
                    ButtonSegment(value: UnidadBase.kilo, label: Text('Kilo')),
                    ButtonSegment(value: UnidadBase.litro, label: Text('Litro')),
                    ButtonSegment(
                      value: UnidadBase.unidad,
                      label: Text('Unidad'),
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
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contenidoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    _unidadBase == UnidadBase.litro
                        ? 'Tamaño envase'
                        : _unidadBase == UnidadBase.kilo
                            ? 'Peso envase'
                            : 'Unidades por envase',
                    hint: _unidadBase == UnidadBase.kilo ? '100 o 0.1' : '1',
                  ),
                ),
                if (_unidadBase != UnidadBase.unidad) ...[
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
                    selected: {_contenidoUnidad},
                    onSelectionChanged: (sel) {
                      setState(() => _contenidoUnidad = sel.first);
                    },
                  ),
                ],
              ],
              if (f.urlCc) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCcCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    'URL C&C',
                    hint: 'https://ccmaxigross-online.it/...',
                  ),
                ),
              ],
              if (f.urlMetro) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _urlMetroCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _deco(
                    'URL Metro',
                    hint: 'https://prodotti.metro.it/...',
                  ),
                ),
              ],
              if (f.precioCc) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _precioCcCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco('Precio C&C (€)'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pegar del portapapeles',
                      onPressed: () => _pegarPortapapelesEn(_precioCcCtrl),
                      icon: const Icon(Icons.content_paste, color: Colors.white54),
                    ),
                  ],
                ),
              ],
              if (f.precioMetro) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _precioMetroCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco('Precio Metro (€)'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pegar del portapapeles',
                      onPressed: () => _pegarPortapapelesEn(_precioMetroCtrl),
                      icon: const Icon(Icons.content_paste, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (
            resultado: ResultadoRevisionPaso.cancelado,
            datos: null,
          )),
          child: const Text('Cancelar todo'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            resultado: ResultadoRevisionPaso.saltado,
            datos: null,
          )),
          child: const Text('Saltar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Guardar y seguir'),
        ),
      ],
    );
  }
}
