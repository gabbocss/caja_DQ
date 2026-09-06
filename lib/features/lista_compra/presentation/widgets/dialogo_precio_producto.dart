import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/item_lista_compra.dart';
import '../../domain/entities/precio_producto.dart';
import '../../domain/entities/unidad_medida.dart';
import '../providers/lista_compra_provider.dart';

/// Diálogo para guardar/actualizar el precio de un producto en un súper.
///
/// Si [supermercadoIdPreferido] está definido (p. ej. «Estoy en»), se preselecciona.
/// Si ya hay precio guardado para ese producto+súper, rellena los campos.
Future<void> mostrarDialogoPrecioProducto(
  BuildContext context, {
  required ItemListaCompra item,
  int? supermercadoIdPreferido,
}) async {
  final provider = context.read<ListaCompraProvider>();
  if (provider.supermercados.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Añade primero supermercados en el menú.'),
      ),
    );
    return;
  }

  var superId = supermercadoIdPreferido ??
      provider.supermercadoActualId ??
      provider.supermercados.first.id;

  PrecioProducto? existente;
  for (final p in provider.preciosDeProducto(item.id)) {
    if (p.supermercadoId == superId) {
      existente = p;
      break;
    }
  }

  final precioCtrl = TextEditingController(
    text: existente != null ? existente.precioEnvase.toStringAsFixed(2) : '',
  );
  final contenidoCtrl = TextEditingController(
    text: existente != null
        ? _numTexto(existente.contenidoCantidad)
        : (item.contenidoCantidad != null
            ? _numTexto(item.contenidoCantidad!)
            : ''),
  );
  var contenidoUnidad = existente?.contenidoUnidad ?? item.contenidoUnidad;
  String? preview = existente == null
      ? null
      : formatearPrecioPorBase(existente.precioPorBase, item.unidadBase);

  void recalc(void Function(void Function()) setLocal) {
    final precio = double.tryParse(precioCtrl.text.replaceAll(',', '.'));
    final cont = double.tryParse(contenidoCtrl.text.replaceAll(',', '.'));
    if (precio == null || cont == null) {
      setLocal(() => preview = null);
      return;
    }
    final p = calcularPrecioPorBase(
      precioEnvase: precio,
      contenidoCantidad: cont,
      contenidoUnidad: contenidoUnidad,
      unidadBase: item.unidadBase,
    );
    setLocal(() => preview = formatearPrecioPorBase(p, item.unidadBase));
  }

  void cargarPrecioDeSuper(int sid, void Function(void Function()) setLocal) {
    PrecioProducto? p;
    for (final x in provider.preciosDeProducto(item.id)) {
      if (x.supermercadoId == sid) {
        p = x;
        break;
      }
    }
    setLocal(() {
      superId = sid;
      if (p != null) {
        precioCtrl.text = p.precioEnvase.toStringAsFixed(2);
        contenidoCtrl.text = _numTexto(p.contenidoCantidad);
        contenidoUnidad = p.contenidoUnidad;
        preview = formatearPrecioPorBase(p.precioPorBase, item.unidadBase);
      } else {
        precioCtrl.clear();
        contenidoCtrl.text = item.contenidoCantidad != null
            ? _numTexto(item.contenidoCantidad!)
            : '';
        contenidoUnidad = item.contenidoUnidad;
        preview = null;
      }
    });
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: Text(
              'Precio: ${item.nombre}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(superId),
                    value: superId,
                    dropdownColor: const Color(0xFF16213E),
                    decoration: const InputDecoration(
                      labelText: 'Supermercado',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: provider.supermercados
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) cargarPrecioDeSuper(v, setLocal);
                    },
                  ),
                  TextField(
                    controller: precioCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Precio del envase (€)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '1.49',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (_) => recalc(setLocal),
                  ),
                  Text(
                    'Producto por ${item.unidadBase.etiqueta.toLowerCase()} '
                    '(${item.unidadBase.etiquetaPrecio})',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (item.unidadBase == UnidadBase.unidad)
                    TextField(
                      controller: contenidoCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Unidades en el envase',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: '1',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onChanged: (_) => recalc(setLocal),
                    )
                  else ...[
                    TextField(
                      controller: contenidoCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: item.unidadBase == UnidadBase.litro
                            ? 'Contenido del envase'
                            : 'Peso del envase',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText:
                            item.unidadBase == UnidadBase.litro ? '750' : '500',
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                      onChanged: (_) => recalc(setLocal),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Medida del envase',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ContenidoUnidad>(
                        segments: ContenidoUnidad.paraBase(item.unidadBase)
                            .map(
                              (u) => ButtonSegment(
                                value: u,
                                label: Text(u.etiquetaLarga),
                              ),
                            )
                            .toList(),
                        selected: {
                          ContenidoUnidad.paraBase(item.unidadBase)
                                  .contains(contenidoUnidad)
                              ? contenidoUnidad
                              : ContenidoUnidad.paraBase(item.unidadBase).first,
                        },
                        onSelectionChanged: (sel) {
                          setLocal(() {
                            contenidoUnidad = sel.first;
                            recalc(setLocal);
                          });
                        },
                        style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.black87;
                            }
                            return Colors.white70;
                          }),
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF4FC3F7);
                            }
                            return const Color(0xFF0D0D0D);
                          }),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    preview == null
                        ? 'Introduce precio y contenido para ver ${item.unidadBase.etiquetaPrecio}'
                        : 'Sale a $preview',
                    style: TextStyle(
                      color: preview == null
                          ? Colors.white54
                          : const Color(0xFF66BB6A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (ok != true || !context.mounted) return;

  final precio = double.tryParse(precioCtrl.text.replaceAll(',', '.'));
  final cont = double.tryParse(contenidoCtrl.text.replaceAll(',', '.'));
  if (precio == null || cont == null || cont <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Precio y contenido deben ser números válidos'),
      ),
    );
    return;
  }

  if (item.unidadBase == UnidadBase.unidad) {
    contenidoUnidad = ContenidoUnidad.ud;
  }

  final exito = await provider.guardarPrecio(
    producto: item,
    supermercadoId: superId,
    precioEnvase: precio,
    contenidoCantidad: cont,
    contenidoUnidad: contenidoUnidad,
  );
  if (!context.mounted) return;
  if (!exito && provider.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error!)),
    );
  } else {
    final p = calcularPrecioPorBase(
      precioEnvase: precio,
      contenidoCantidad: cont,
      contenidoUnidad: contenidoUnidad,
      unidadBase: item.unidadBase,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Guardado: ${precio.toStringAsFixed(2)} € · '
          '${formatearPrecioPorBase(p, item.unidadBase)}',
        ),
      ),
    );
  }
}

String _numTexto(double n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toString();
}
