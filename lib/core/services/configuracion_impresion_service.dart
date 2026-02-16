import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/configuracion_impresion.dart';

/// Carga y guarda la configuración de impresión en JSON (programa_caja_db/configuracion_impresion.json).
class ConfiguracionImpresionService {
  static ConfiguracionImpresionService? _instance;
  static ConfiguracionImpresionService get instance {
    _instance ??= ConfiguracionImpresionService._();
    return _instance!;
  }

  ConfiguracionImpresionService._();

  ConfiguracionImpresion? _cache;

  Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return '${dir.path}/programa_caja_db/configuracion_impresion.json';
  }

  /// Carga la configuración desde disco. Si no existe, devuelve la por defecto.
  Future<ConfiguracionImpresion> cargar() async {
    if (_cache != null) return _cache!;
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _cache = ConfiguracionImpresion.fromJson(json);
        return _cache!;
      }
    } catch (e) {
      debugPrint('Error cargando configuracion impresion: $e');
    }
    _cache = ConfiguracionImpresion();
    return _cache!;
  }

  /// Guarda la configuración y actualiza la caché.
  Future<void> guardar(ConfiguracionImpresion config) async {
    try {
      final path = await _getFilePath();
      await File(path).writeAsString(const JsonEncoder.withIndent('  ').convert(config.toJson()));
      _cache = config;
    } catch (e) {
      debugPrint('Error guardando configuracion impresion: $e');
    }
  }

  /// Invalida la caché para forzar recarga en la siguiente lectura.
  void invalidarCache() {
    _cache = null;
  }
}
