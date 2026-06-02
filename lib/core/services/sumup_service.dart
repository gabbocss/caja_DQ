import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/sumup_config.dart';
import 'sumup_config_service.dart';

/// Línea enviada a SumUp (precio bruto con IVA incluido).
class SumUpLineaVenta {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  const SumUpLineaVenta({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;
}

/// Resultado del cobro en el terminal SumUp.
enum SumUpCobroEstado {
  aprobado,
  denegado,
  cancelado,
  timeout,
  errorConfiguracion,
  errorRed,
}

class SumUpCobroResultado {
  final SumUpCobroEstado estado;
  final String? mensaje;
  final String? clientTransactionId;
  final String? transactionId;

  const SumUpCobroResultado({
    required this.estado,
    this.mensaje,
    this.clientTransactionId,
    this.transactionId,
  });

  bool get esExitoso => estado == SumUpCobroEstado.aprobado;
}

/// Comunicación con la POS Cloud API de SumUp (checkout en reader + polling).
class SumUpService {
  static final SumUpService instance = SumUpService._();
  SumUpService._();

  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(minutes: 3);

  final _uuid = const Uuid();

  Future<SumUpConfig> _config() => SumUpConfigService.instance.cargar();

  /// Inicia cobro en el TPV SumUp y espera resultado (aprobado / denegado / cancelado).
  Future<SumUpCobroResultado> cobrarEnTerminal({
    required int mesaNumero,
    required double importeEuros,
    required List<SumUpLineaVenta> lineas,
    bool esPagoParcial = false,
  }) async {
    final config = await _config();
    if (!config.estaCompleta) {
      return const SumUpCobroResultado(
        estado: SumUpCobroEstado.errorConfiguracion,
        mensaje:
            'Configure SumUp en programa_caja_db/sumup_config.json (API key, merchant, reader, affiliate).',
      );
    }

    if (importeEuros <= 0 || importeEuros.isNaN || importeEuros.isInfinite) {
      return const SumUpCobroResultado(
        estado: SumUpCobroEstado.errorConfiguracion,
        mensaje: 'Importe de cobro no válido',
      );
    }

    final clientTransactionId =
        'mesa-${mesaNumero}-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 8)}';
    final centimos = (importeEuros * 100).round();
    final descripcion = _construirDescripcion(mesaNumero, lineas, esPagoParcial);

    try {
      final checkoutOk = await _crearCheckoutReader(
        config: config,
        mesaNumero: mesaNumero,
        clientTransactionId: clientTransactionId,
        centimos: centimos,
        descripcion: descripcion,
      );
      if (!checkoutOk) {
        return const SumUpCobroResultado(
          estado: SumUpCobroEstado.errorRed,
          mensaje: 'No se pudo iniciar el cobro en el terminal SumUp',
        );
      }

      final estadoTx = await _esperarTransaccion(
        config: config,
        clientTransactionId: clientTransactionId,
      );

      switch (estadoTx.estado) {
        case _TxEstado.successful:
          return SumUpCobroResultado(
            estado: SumUpCobroEstado.aprobado,
            clientTransactionId: clientTransactionId,
            transactionId: estadoTx.transactionId,
          );
        case _TxEstado.failed:
          return SumUpCobroResultado(
            estado: SumUpCobroEstado.denegado,
            mensaje: 'Pago denegado en el terminal',
            clientTransactionId: clientTransactionId,
          );
        case _TxEstado.cancelled:
          return SumUpCobroResultado(
            estado: SumUpCobroEstado.cancelado,
            mensaje: 'Pago cancelado en el terminal',
            clientTransactionId: clientTransactionId,
          );
        case _TxEstado.timeout:
          return SumUpCobroResultado(
            estado: SumUpCobroEstado.timeout,
            mensaje: 'Tiempo de espera agotado en el terminal',
            clientTransactionId: clientTransactionId,
          );
        case _TxEstado.pending:
          return SumUpCobroResultado(
            estado: SumUpCobroEstado.cancelado,
            mensaje: 'Pago no completado en el terminal',
            clientTransactionId: clientTransactionId,
          );
      }
    } catch (e, st) {
      debugPrint('SumUp cobro error: $e\n$st');
      return SumUpCobroResultado(
        estado: SumUpCobroEstado.errorRed,
        mensaje: e.toString(),
        clientTransactionId: clientTransactionId,
      );
    }
  }

  String _construirDescripcion(
    int mesa,
    List<SumUpLineaVenta> lineas,
    bool esPagoParcial,
  ) {
    final buf = StringBuffer();
    buf.write('Mesa $mesa');
    if (esPagoParcial) buf.write(' (pago parcial)');
    buf.write('\n');
    for (final l in lineas) {
      buf.writeln('${l.cantidad}x ${l.nombre} ${l.subtotal.toStringAsFixed(2)}€');
    }
    final maxLen = 240;
    final s = buf.toString();
    return s.length <= maxLen ? s : '${s.substring(0, maxLen - 3)}...';
  }

  Future<bool> _crearCheckoutReader({
    required SumUpConfig config,
    required int mesaNumero,
    required String clientTransactionId,
    required int centimos,
    required String descripcion,
  }) async {
    final url = Uri.parse(
      '${config.apiBaseUrl}/v0.1/merchants/${config.merchantCode}/readers/${config.readerId}/checkout',
    );
    final body = {
      'total_amount': {
        'currency': config.currency,
        'minor_unit': 2,
        'value': centimos,
      },
      'description': descripcion,
      'affiliate': {
        'app_id': config.affiliateAppId,
        'foreign_transaction_id': clientTransactionId,
        'metadata': {'mesa': mesaNumero.toString()},
      },
    };

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('SumUp checkout iniciado: $clientTransactionId');
      return true;
    }
    debugPrint(
      'SumUp checkout falló ${response.statusCode}: ${response.body}',
    );
    return false;
  }

  Future<_TxPollResult> _esperarTransaccion({
    required SumUpConfig config,
    required String clientTransactionId,
  }) async {
    final deadline = DateTime.now().add(_pollTimeout);
    var vioActividad = false;

    while (DateTime.now().isBefore(deadline)) {
      final readerState = await _obtenerEstadoReader(config);
      if (readerState != null &&
          readerState != 'IDLE' &&
          readerState != 'SELECTING_TIP') {
        vioActividad = true;
      }

      final tx = await _consultarTransaccion(config, clientTransactionId);
      if (tx != null) {
        switch (tx.estado) {
          case _TxEstado.successful:
            return tx;
          case _TxEstado.failed:
          case _TxEstado.cancelled:
            return tx;
          case _TxEstado.pending:
            break;
          case _TxEstado.timeout:
            break;
        }
      }

      if (vioActividad && readerState == 'IDLE' && tx == null) {
        await Future<void>.delayed(_pollInterval);
        final tx2 = await _consultarTransaccion(config, clientTransactionId);
        if (tx2 != null) return tx2;
        return const _TxPollResult(estado: _TxEstado.cancelled);
      }

      await Future<void>.delayed(_pollInterval);
    }

    return const _TxPollResult(estado: _TxEstado.timeout);
  }

  Future<String?> _obtenerEstadoReader(SumUpConfig config) async {
    final url = Uri.parse(
      '${config.apiBaseUrl}/v0.1/merchants/${config.merchantCode}/readers/${config.readerId}/status',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      return data?['state'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<_TxPollResult?> _consultarTransaccion(
    SumUpConfig config,
    String clientTransactionId,
  ) async {
    final url = Uri.parse(
      '${config.apiBaseUrl}/v2.1/merchants/${config.merchantCode}/transactions',
    ).replace(
      queryParameters: {'client_transaction_id': clientTransactionId},
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (json['status'] as String?)?.toUpperCase() ?? '';
      final id = json['id'] as String?;

      _TxEstado map;
      if (status == 'SUCCESSFUL' || status == 'PAID') {
        map = _TxEstado.successful;
      } else if (status == 'FAILED') {
        map = _TxEstado.failed;
      } else if (status == 'CANCELLED') {
        map = _TxEstado.cancelled;
      } else {
        map = _TxEstado.pending;
      }

      return _TxPollResult(estado: map, transactionId: id);
    } catch (_) {
      return null;
    }
  }
}

enum _TxEstado { successful, failed, cancelled, pending, timeout }

class _TxPollResult {
  final _TxEstado estado;
  final String? transactionId;

  const _TxPollResult({required this.estado, this.transactionId});
}
