import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio que mantiene el número de ticket; se reinicia cada medianoche.
class TicketNumeroService {
  static TicketNumeroService? _instance;
  static TicketNumeroService get instance {
    _instance ??= TicketNumeroService._();
    return _instance!;
  }

  TicketNumeroService._();

  static String get _fechaHoy => DateTime.now().toIso8601String().substring(0, 10);

  Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${dir.path}/programa_caja_db');
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    return '${dir.path}/programa_caja_db/ticket_numero.json';
  }

  /// Obtiene el siguiente número de ticket (incrementa y persiste). Reinicia a 1 cada día.
  Future<int> obtenerSiguienteNumero() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      int numero = 1;
      String fecha = _fechaHoy;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final fechaGuardada = json['fecha'] as String? ?? '';
        if (fechaGuardada == _fechaHoy) {
          numero = (json['numero'] as num?)?.toInt() ?? 0;
          numero++;
        }
      }
      await file.writeAsString(const JsonEncoder().convert({
        'fecha': _fechaHoy,
        'numero': numero,
      }));
      return numero;
    } catch (e) {
      debugPrint('Error en TicketNumeroService: $e');
      return 1;
    }
  }
}
