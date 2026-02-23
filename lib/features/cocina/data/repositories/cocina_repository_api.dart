import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/models/models.dart';
import '../../domain/repositories/cocina_repository.dart';

/// Implementación del repositorio de Cocina que usa la API (para la app web).
/// Sustituye a CocinaRepositoryImpl cuando no hay base de datos local.
class CocinaRepositoryApi implements CocinaRepository {
  final ApiClient _api;
  static const Duration _pollingInterval = Duration(seconds: 4);

  CocinaRepositoryApi(this._api);

  @override
  Future<List<Pedido>> obtenerPedidosCocina() async {
    return _api.obtenerPedidosCocina();
  }

  @override
  Future<void> iniciarPreparacion(int pedidoId) async {
    await _api.actualizarEstadoPedido(pedidoId, EstadoPedido.preparando);
  }

  @override
  Future<void> marcarListo(int pedidoId) async {
    await _api.actualizarEstadoPedido(pedidoId, EstadoPedido.listo);
  }

  @override
  Future<void> actualizarEstadoItem(
    int pedidoId,
    int itemIndex,
    EstadoPedido nuevoEstado,
  ) async {
    await _api.actualizarEstadoItem(pedidoId, itemIndex, nuevoEstado);
  }

  @override
  Stream<List<Pedido>> watchPedidosCocina() {
    Future<List<Pedido>> fetch() async {
      try {
        return await _api.obtenerPedidosCocina();
      } catch (_) {
        return <Pedido>[];
      }
    }

    return Stream.fromFuture(fetch()).asyncExpand((initial) {
      return Stream.value(initial).asyncExpand((_) {
        return Stream.periodic(_pollingInterval, (_) {}).asyncMap((_) => fetch());
      });
    });
  }
}
