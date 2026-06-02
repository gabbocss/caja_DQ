import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/sumup_config.dart';

/// Carga/guarda configuración SumUp en programa_caja_db/sumup_config.json
class SumUpConfigService {
  static final SumUpConfigService instance = SumUpConfigService._();
  SumUpConfigService._();

  SumUpConfig? _cache;

  Future<String> _ruta() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return '${dir.path}/programa_caja_db/sumup_config.json';
  }

  Future<SumUpConfig> cargar() async {
    if (_cache != null) return _cache!;
    try {
      final file = File(await _ruta());
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _cache = SumUpConfig.fromJson(json);
        return _cache!;
      }
    } catch (e) {
      debugPrint('Error cargando sumup_config: $e');
    }
    _cache = const SumUpConfig();
    return _cache!;
  }

  Future<void> guardar(SumUpConfig config) async {
    await File(await _ruta()).writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );
    _cache = config;
  }

  void invalidarCache() => _cache = null;
}
