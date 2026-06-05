import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/producto.dart';

/// Caché local de la carta de productos para reservas en móvil (sin Isar).
class ReservaCartaCacheService {
  static final ReservaCartaCacheService instance = ReservaCartaCacheService._();
  ReservaCartaCacheService._();

  static const _archivo = 'reservas_carta_cache.json';

  Future<String> _rutaArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/programa_caja_db');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return '${carpeta.path}/$_archivo';
  }

  Future<List<Producto>> cargar() async {
    try {
      final path = await _rutaArchivo();
      final file = File(path);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Producto.fromJson)
          .toList();
    } catch (e) {
      debugPrint('ReservaCartaCache: error leyendo: $e');
      return [];
    }
  }

  Future<void> guardar(List<Producto> productos) async {
    try {
      final path = await _rutaArchivo();
      final payload = productos.map((p) => p.toJson()).toList();
      await File(path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      debugPrint('ReservaCartaCache: ${productos.length} productos ($path)');
    } catch (e) {
      debugPrint('ReservaCartaCache: error guardando: $e');
      rethrow;
    }
  }
}
