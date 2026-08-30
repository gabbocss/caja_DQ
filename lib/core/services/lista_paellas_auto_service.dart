import 'package:flutter/foundation.dart';

import '../models/reserva.dart';
import '../prefs/horarios_reservas_prefs.dart';
import '../prefs/lista_paellas_prefs.dart';
import 'imprimir_pedido_service.dart';
import 'reserva_persistence_service.dart';

/// Impresión automática según horarios de apertura configurados en Reservas.
///
/// - Ventana común de inicio: **1 h 30 min antes** de `comidaInicio` / `cenaInicio`.
/// - Mesas («Lista paellas»): solo reservas **nuevas** (aún no enviadas), hasta
///   **30 min antes** de la apertura.
/// - Asporto: mismo inicio; tickets individuales de los nuevos hasta **fin de servicio**.
/// - Barra: desde **60 min antes** hasta fin de servicio, aviso «NUEVA RESERVA» /
///   «NUEVO ASPORTO» (hora + cubiertos) solo para altas creadas en esa ventana.
///
/// Se evalúa tras cada sync OK del VPS (~15 s).
class ListaPaellasAutoService {
  static final ListaPaellasAutoService instance = ListaPaellasAutoService._();
  ListaPaellasAutoService._();

  static const Duration _antesInicio = Duration(hours: 1, minutes: 30);
  static const Duration _corteMesasAntesApertura = Duration(minutes: 30);
  static const Duration _avisoBarraAntesApertura = Duration(hours: 1);

  bool _enCurso = false;

  /// Llamar tras un pull de reservas exitoso.
  Future<void> evaluarTrasSync() async {
    if (_enCurso) return;
    _enCurso = true;
    try {
      final horarios = await getHorariosReservas();
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      await _evaluarServicio(
        dia: hoy,
        ahora: ahora,
        esComida: true,
        horarios: horarios,
      );
      await _evaluarServicio(
        dia: hoy,
        ahora: ahora,
        esComida: false,
        horarios: horarios,
      );
    } catch (e, st) {
      debugPrint('ListaPaellasAuto: $e\n$st');
    } finally {
      _enCurso = false;
    }
  }

  Future<void> _evaluarServicio({
    required DateTime dia,
    required DateTime ahora,
    required bool esComida,
    required HorariosReservas horarios,
  }) async {
    final inicioMin =
        esComida ? horarios.comidaInicioMin : horarios.cenaInicioMin;
    final finMin = esComida ? horarios.comidaFinMin : horarios.cenaFinMin;

    final apertura = _instanteDelDia(dia, inicioMin);
    final finServicio = _instanteDelDia(dia, finMin);
    final inicioVentana = apertura.subtract(_antesInicio);
    final corteMesas = apertura.subtract(_corteMesasAntesApertura);

    // Aún no ha empezado la ventana de prep (1h30 antes).
    if (ahora.isBefore(inicioVentana)) return;

    final reservas =
        await ReservaPersistenceService.instance.obtenerReservasDelDia(dia);

    final yaMesas = await idsMesasYaEnviados(dia);
    final yaAsporto = await idsAsportoYaEnviados(dia);

    final mesasNuevas = <Reserva>[];
    final asportosNuevos = <Reserva>[];

    for (final r in reservas) {
      if (r.id == null) continue;
      if (r.estado == EstadoReserva.cancelada ||
          r.estado == EstadoReserva.cobrada) {
        continue;
      }

      if (r.numeroPersonas <= 0) {
        if (_enRangoLlegada(r, inicioMin, finMin) &&
            !yaAsporto.contains(r.id)) {
          asportosNuevos.add(r);
        }
        continue;
      }

      if (_esDelServicio(r, esComida: esComida, horarios: horarios) &&
          !yaMesas.contains(r.id)) {
        mesasNuevas.add(r);
      }
    }

    // Mesas: solo hasta 30 min antes de la apertura.
    final enVentanaMesas = !ahora.isAfter(corteMesas);
    if (enVentanaMesas && mesasNuevas.isNotEmpty) {
      final lineas = <String>[];
      final idsImpresos = <int>[];
      for (final r in mesasNuevas) {
        var tienePlatos = false;
        for (final item in r.itemsReservados) {
          if (item.cantidad <= 0) continue;
          lineas.add('${item.nombreProducto} x${item.cantidad}');
          tienePlatos = true;
        }
        if (tienePlatos) idsImpresos.add(r.id!);
      }
      if (lineas.isNotEmpty) {
        await ImprimirPedidoService.instance.imprimirListaPaellas(lineas);
        await marcarMesasEnviadas(
          dia,
          ids: idsImpresos,
        );
        debugPrint(
          'ListaPaellasAuto: lista ${esComida ? 'comida' : 'cena'} '
          'incremental (${lineas.length} líneas, ${idsImpresos.length} reservas)',
        );
      } else {
        // Sin platos: marcar igual para no reintentar en bucle.
        await marcarMesasEnviadas(
          dia,
          ids: mesasNuevas.map((r) => r.id!).whereType<int>(),
        );
      }
    }

    // Asporto: desde el mismo inicio hasta fin de servicio.
    final enVentanaAsporto = !ahora.isAfter(finServicio);
    if (enVentanaAsporto && asportosNuevos.isNotEmpty) {
      final idsOk = <int>[];
      for (final r in asportosNuevos) {
        if (r.itemsReservados.isEmpty) {
          idsOk.add(r.id!);
          continue;
        }
        await ImprimirPedidoService.instance.imprimirTicketReservaCocina(
          mesaNumero: 0,
          reserva: r,
          etiquetaCabecera: 'ASPORTO',
        );
        idsOk.add(r.id!);
        debugPrint(
          'ListaPaellasAuto: asporto individual "${r.nombreCliente}"',
        );
      }
      await marcarAsportosEnviados(
        dia,
        ids: idsOk,
      );
    }

    // Barra: desde 60 min antes de la apertura hasta fin de servicio.
    final inicioBarra = apertura.subtract(_avisoBarraAntesApertura);
    final enVentanaBarra =
        !ahora.isBefore(inicioBarra) && !ahora.isAfter(finServicio);
    if (enVentanaBarra) {
      await _avisarBarraReservasNuevas(
        dia: dia,
        esComida: esComida,
        inicioBarra: inicioBarra,
        mesas: reservas.where((r) {
          if (r.id == null) return false;
          if (r.estado == EstadoReserva.cancelada ||
              r.estado == EstadoReserva.cobrada) {
            return false;
          }
          if (r.numeroPersonas <= 0) return false;
          return _esDelServicio(r, esComida: esComida, horarios: horarios);
        }).toList(),
        asportos: reservas.where((r) {
          if (r.id == null) return false;
          if (r.estado == EstadoReserva.cancelada ||
              r.estado == EstadoReserva.cobrada) {
            return false;
          }
          if (r.numeroPersonas > 0) return false;
          return _enRangoLlegada(r, inicioMin, finMin);
        }).toList(),
      );
    }
  }

  Future<void> _avisarBarraReservasNuevas({
    required DateTime dia,
    required bool esComida,
    required DateTime inicioBarra,
    required List<Reserva> mesas,
    required List<Reserva> asportos,
  }) async {
    final yaAvisados = await idsBarraYaAvisados(dia);
    final idsMarcados = <int>[];

    for (final r in mesas) {
      final id = r.id!;
      if (yaAvisados.contains(id)) continue;
      if (!r.fechaCreacion.isBefore(inicioBarra)) {
        await ImprimirPedidoService.instance.imprimirAvisoBarra(
          titulo: 'NUEVA RESERVA',
          lineas: _lineasAvisoBarra(r),
        );
        debugPrint(
          'ListaPaellasAuto: aviso barra reserva "${r.nombreCliente}"',
        );
      }
      idsMarcados.add(id);
    }

    for (final r in asportos) {
      final id = r.id!;
      if (yaAvisados.contains(id)) continue;
      if (!r.fechaCreacion.isBefore(inicioBarra)) {
        await ImprimirPedidoService.instance.imprimirAvisoBarra(
          titulo: 'NUEVO ASPORTO',
          lineas: _lineasAvisoBarra(r),
        );
        debugPrint(
          'ListaPaellasAuto: aviso barra asporto "${r.nombreCliente}"',
        );
      }
      idsMarcados.add(id);
    }

    await marcarBarraAvisados(dia, ids: idsMarcados);
  }

  List<String> _lineasAvisoBarra(Reserva r) {
    final hora =
        '${r.fechaHoraLlegada.hour.toString().padLeft(2, '0')}:'
        '${r.fechaHoraLlegada.minute.toString().padLeft(2, '0')}';
    final n = r.numeroPersonas;
    final cubiertos = n == 1 ? '1 cubierto' : '$n cubiertos';
    return [hora, cubiertos];
  }

  DateTime _instanteDelDia(DateTime dia, int minutosDelDia) {
    final m = minutosDelDia.clamp(0, 23 * 60 + 59);
    return DateTime(dia.year, dia.month, dia.day, m ~/ 60, m % 60);
  }

  /// Misma regla que [clasificarReserva] en la agenda: comida tiene prioridad
  /// si la hora cae en ambos rangos (evita imprimir dos veces comida+cena).
  bool _esDelServicio(
    Reserva r, {
    required bool esComida,
    required HorariosReservas horarios,
  }) {
    final minutos =
        r.fechaHoraLlegada.hour * 60 + r.fechaHoraLlegada.minute;

    final bool esComidaReserva;
    if (_enRango(minutos, horarios.comidaInicioMin, horarios.comidaFinMin)) {
      esComidaReserva = true;
    } else if (_enRango(minutos, horarios.cenaInicioMin, horarios.cenaFinMin)) {
      esComidaReserva = false;
    } else {
      esComidaReserva = minutos < horarios.cenaInicioMin;
    }
    return esComidaReserva == esComida;
  }

  bool _enRangoLlegada(Reserva r, int inicio, int fin) {
    final minutos =
        r.fechaHoraLlegada.hour * 60 + r.fechaHoraLlegada.minute;
    return _enRango(minutos, inicio, fin);
  }

  bool _enRango(int minutos, int inicio, int fin) {
    if (inicio <= fin) {
      return minutos >= inicio && minutos <= fin;
    }
    return minutos >= inicio || minutos <= fin;
  }
}
