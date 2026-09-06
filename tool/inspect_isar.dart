// ignore_for_file: avoid_print
/// Abre restaurante.isar y lista datos sin usar el inspector web.
///
/// Uso:
///   dart run tool/inspect_isar.dart
///   dart run tool/inspect_isar.dart --buscar garcia
///   dart run tool/inspect_isar.dart --id 294
///   dart run tool/inspect_isar.dart --dia 2026-08-29
///   dart run tool/inspect_isar.dart --ruta ~/Documentos/programa_caja_db
///   dart run tool/inspect_isar.dart --json
///
/// Cierra programa_caja antes de ejecutar (Isar bloquea el archivo).

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:programa_caja/core/models/models.dart';

const _nombreDb = 'restaurante';

/// Descarga Isar Core 3.3.x en carpeta fija (evita binarios viejos 3.1 en tool/).
Future<void> _inicializarIsarCore() async {
  final home = Platform.environment['HOME'] ?? '.';
  final libDir = Directory('$home/Documentos/programa_caja_db/isar_core');
  if (!await libDir.exists()) {
    await libDir.create(recursive: true);
  }
  final libPath = '${libDir.path}/${Abi.current().localName}';
  final libFile = File(libPath);
  if (await libFile.exists()) {
    await libFile.delete();
  }
  await Isar.initializeIsarCore(
    download: true,
    libraries: {Abi.current(): libPath},
  );
}

Future<void> main(List<String> args) async {
  final opciones = _parseArgs(args);
  final dbDir = opciones.rutaDb;

  if (!await Directory(dbDir).exists()) {
    stderr.writeln('No existe la carpeta de base de datos: $dbDir');
    exit(1);
  }

  final lock = File('$dbDir/$_nombreDb.isar.lock');
  if (await lock.exists()) {
    stderr.writeln(
      'La base de datos está en uso (hay un .lock). '
      'Cierra programa_caja y vuelve a ejecutar.',
    );
    exit(1);
  }

  await _inicializarIsarCore();

  final isar = await Isar.open(
    [
      ProductoSchema,
      MesaSchema,
      PedidoSchema,
      DestinoImpresionSchema,
      ConfiguracionBuffetSchema,
      CategoriaSchema,
      CarritoQrMesaSchema,
      BuffetLimiteQrMesaSchema,
      ReservaSchema,
    ],
    directory: dbDir,
    name: _nombreDb,
    inspector: false,
  );

  try {
    await _mostrarResumen(isar, opciones);
  } finally {
    await isar.close();
  }
}

class _Opciones {
  const _Opciones({
    required this.rutaDb,
    this.buscar,
    this.id,
    this.dia,
    this.soloJson = false,
  });

  final String rutaDb;
  final String? buscar;
  final int? id;
  final DateTime? dia;
  final bool soloJson;
}

_Opciones _parseArgs(List<String> args) {
  var ruta = '${Platform.environment['HOME']}/Documentos/programa_caja_db';
  String? buscar;
  int? id;
  DateTime? dia;
  var soloJson = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--ruta':
        ruta = _siguienteValor(args, ++i, arg);
      case '--buscar':
        buscar = _siguienteValor(args, ++i, arg);
      case '--id':
        id = int.parse(_siguienteValor(args, ++i, arg));
      case '--dia':
        dia = DateTime.parse(_siguienteValor(args, ++i, arg));
      case '--json':
        soloJson = true;
      case '-h':
      case '--help':
        _mostrarAyuda();
        exit(0);
      default:
        if (arg.startsWith('-')) {
          stderr.writeln('Opción desconocida: $arg');
          _mostrarAyuda();
          exit(1);
        }
    }
  }

  if (ruta.startsWith('~/')) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      ruta = ruta.replaceFirst('~', home);
    }
  }

  return _Opciones(
    rutaDb: ruta,
    buscar: buscar?.toLowerCase(),
    id: id,
    dia: dia,
    soloJson: soloJson,
  );
}

String _siguienteValor(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Falta valor para $flag');
    exit(1);
  }
  return args[index];
}

void _mostrarAyuda() {
  print('''
Inspector local de Isar (programa_caja)

Comandos:
  dart run tool/inspect_isar.dart
  dart run tool/inspect_isar.dart --buscar garcia
  dart run tool/inspect_isar.dart --id 294
  dart run tool/inspect_isar.dart --dia 2026-08-29
  dart run tool/inspect_isar.dart --ruta ~/Documentos/programa_caja_db
  dart run tool/inspect_isar.dart --json

Opciones:
  --ruta    Carpeta que contiene restaurante.isar (por defecto ~/Documentos/programa_caja_db)
  --buscar  Filtra reservas por nombre (sin distinguir mayúsculas)
  --id      Muestra una reserva concreta
  --dia     Solo reservas de ese día (YYYY-MM-DD)
  --json    Salida en JSON en lugar de texto
''');
}

Future<void> _mostrarResumen(Isar isar, _Opciones opciones) async {
  var reservas = await isar.reservas.where().sortByFechaHoraLlegada().findAll();

  if (opciones.id != null) {
    final una = await isar.reservas.get(opciones.id!);
    reservas = una == null ? [] : [una];
  } else {
    if (opciones.dia != null) {
      final inicio = DateTime(
        opciones.dia!.year,
        opciones.dia!.month,
        opciones.dia!.day,
      );
      final fin = inicio.add(const Duration(days: 1));
      reservas = reservas
          .where(
            (r) =>
                !r.fechaHoraLlegada.isBefore(inicio) &&
                r.fechaHoraLlegada.isBefore(fin),
          )
          .toList();
    }
    if (opciones.buscar != null) {
      final q = opciones.buscar!;
      reservas = reservas
          .where((r) => r.nombreCliente.toLowerCase().contains(q))
          .toList();
    }
  }

  if (opciones.soloJson) {
    final payload = reservas.map((r) => r.toJson()).toList();
    print(const JsonEncoder.withIndent('  ').convert(payload));
    return;
  }

  final productos = await isar.productos.count();
  final mesas = await isar.mesas.count();
  final pedidos = await isar.pedidos.count();
  final totalReservas = await isar.reservas.count();

  print('═══════════════════════════════════════════════════════════');
  print('  Isar: ${opciones.rutaDb}/$_nombreDb.isar');
  print('═══════════════════════════════════════════════════════════');
  print('Colecciones:');
  print('  Reservas : $totalReservas');
  print('  Productos: $productos');
  print('  Mesas    : $mesas');
  print('  Pedidos  : $pedidos');
  print('───────────────────────────────────────────────────────────');

  if (reservas.isEmpty) {
    print('No hay reservas con esos filtros.');
    return;
  }

  print('Reservas mostradas: ${reservas.length}');
  print('');

  for (final r in reservas) {
    _imprimirReserva(r);
    print('');
  }
}

void _imprimirReserva(Reserva r) {
  final llegada = _formatoFecha(r.fechaHoraLlegada);
  final actualizado = _formatoFecha(r.fechaActualizacion);
  final platos = r.itemsReservados.length;
  final mesa = r.mesaAsignada == null ? '-' : 'M${r.mesaAsignada}';

  print('ID ${r.id} | $llegada | ${r.estado.name.padRight(9)} | $mesa');
  print('  Cliente : ${r.nombreCliente}');
  print('  Personas: ${r.numeroPersonas} | Platos: $platos');
  if (r.alergiasNotas.trim().isNotEmpty) {
    print('  Notas   : ${r.alergiasNotas}');
  }
  print('  Creada  : ${_formatoFecha(r.fechaCreacion)}');
  print('  Editada : $actualizado');
  if (r.itemsReservados.isNotEmpty) {
    print('  Ítems   :');
    for (final item in r.itemsReservados) {
      print(
        '    - ${item.cantidad}x ${item.nombreProducto} '
        '(${item.precioUnitario.toStringAsFixed(2)} €)',
      );
    }
  }
}

String _formatoFecha(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year} $h:$min';
}
