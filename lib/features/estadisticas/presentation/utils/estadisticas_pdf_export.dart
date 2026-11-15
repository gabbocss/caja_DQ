import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/core.dart';
import '../../data/estadisticas_service.dart';

/// Genera y guarda un PDF de estadísticas con tablas y gráficas de barras.
class EstadisticasPdfExport {
  EstadisticasPdfExport._();

  static const _verde = PdfColor.fromInt(0xFF00A878);
  static const _naranja = PdfColor.fromInt(0xFFE67E22);
  static const _azul = PdfColor.fromInt(0xFF1A5276);
  static const _grisClaro = PdfColor.fromInt(0xFFEEF2F5);

  /// Devuelve la ruta del archivo guardado, o null si el usuario canceló.
  static Future<String?> exportar({
    required DateTime desde,
    required DateTime hasta,
    String? categoria,
    required List<PlatoMasPedido> platos,
    required List<TiempoMedioPlato> tiemposPlato,
  }) async {
    final bytes = await _construirPdf(
      desde: desde,
      hasta: hasta,
      categoria: categoria,
      platos: platos,
      tiemposPlato: tiemposPlato,
    );

    final fmt = DateFormat('yyyyMMdd');
    final nombre =
        'estadisticas_${fmt.format(desde)}_${fmt.format(hasta)}.pdf';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar PDF de estadísticas',
      fileName: nombre,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (path == null) return null;

    final filePath = path.toLowerCase().endsWith('.pdf') ? path : '$path.pdf';
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  static Future<Uint8List> _construirPdf({
    required DateTime desde,
    required DateTime hasta,
    String? categoria,
    required List<PlatoMasPedido> platos,
    required List<TiempoMedioPlato> tiemposPlato,
  }) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');
    final periodo =
        '${fmt.format(desde)} — ${fmt.format(hasta)}'
        '${categoria != null && categoria.isNotEmpty ? ' · Categoría: $categoria' : ''}';

    final totalUnidades =
        platos.fold<int>(0, (s, p) => s + p.cantidadTotal);
    final totalRegTiempos =
        tiemposPlato.fold<int>(0, (s, t) => s + t.cantidadRegistros);
    final tiempoMedioGeneral = _tiempoMedioGeneral(tiemposPlato);

    final topPlatos = platos.take(12).toList();
    final topTiempos = List<TiempoMedioPlato>.from(tiemposPlato)
      ..sort((a, b) => b.tiempoMedioMinutos.compareTo(a.tiempoMedioMinutos));
    final topTiemposChart = topTiempos.take(12).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 32),
        header: (ctx) => _cabecera(periodo),
        footer: (ctx) => _pie(ctx.pageNumber, ctx.pagesCount),
        build: (ctx) => [
          _resumen(
            totalPlatosDistintos: platos.length,
            totalUnidades: totalUnidades,
            totalRegTiempos: totalRegTiempos,
            tiempoMedioGeneral: tiempoMedioGeneral,
          ),
          pw.SizedBox(height: 22),
          _tituloSeccion('Platos más pedidos'),
          pw.SizedBox(height: 6),
          pw.Text(
            'Top ${topPlatos.length} por cantidad vendida en el período.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          if (topPlatos.isEmpty)
            pw.Text(
              'Sin datos en el período seleccionado.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            )
          else ...[
            _graficaBarrasPlatos(topPlatos),
            pw.SizedBox(height: 16),
            _tablaPlatos(platos.take(30).toList()),
          ],
          pw.SizedBox(height: 24),
          _tituloSeccion(
            'Tiempo medio por plato (Empezar → Hecho)',
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Registros con tiempo: $totalRegTiempos. '
            'Media general: ${tiempoMedioGeneral.toStringAsFixed(1)} min.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          if (topTiemposChart.isEmpty)
            pw.Text(
              'Sin tiempos registrados. Se miden en cocina al marcar '
              '"preparando" y luego "listo".',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            )
          else ...[
            _graficaBarrasTiempos(topTiemposChart),
            pw.SizedBox(height: 16),
            _tablaTiempos(tiemposPlato.take(30).toList()),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static double _tiempoMedioGeneral(List<TiempoMedioPlato> tiempos) {
    if (tiempos.isEmpty) return 0;
    final totalMin = tiempos.fold<double>(
      0,
      (s, t) => s + t.tiempoMedioMinutos * t.cantidadRegistros,
    );
    final totalReg =
        tiempos.fold<int>(0, (s, t) => s + t.cantidadRegistros);
    return totalReg > 0 ? totalMin / totalReg : 0;
  }

  static pw.Widget _cabecera(String periodo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Estadísticas — ${AppConstants.appName}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _azul,
              ),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          periodo,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400, thickness: 0.6),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _pie(int pagina, int total) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Text(
          'Página $pagina de $total',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _tituloSeccion(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: _grisClaro,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _azul,
        ),
      ),
    );
  }

  static pw.Widget _resumen({
    required int totalPlatosDistintos,
    required int totalUnidades,
    required int totalRegTiempos,
    required double tiempoMedioGeneral,
  }) {
    pw.Widget tarjeta(String etiqueta, String valor, PdfColor acento) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                etiqueta,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                valor,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: acento,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        tarjeta('Platos distintos', '$totalPlatosDistintos', _azul),
        tarjeta('Unidades pedidas', '$totalUnidades', _verde),
        tarjeta('Registros tiempo', '$totalRegTiempos', _naranja),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Media prep. (min)',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  tiempoMedioGeneral.toStringAsFixed(1),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _naranja,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _graficaBarrasPlatos(List<PlatoMasPedido> platos) {
    final max = platos.first.cantidadTotal.toDouble();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < platos.length; i++)
          _barra(
            etiqueta: '${i + 1}. ${platos[i].nombreProducto}',
            valorTexto: '${platos[i].cantidadTotal}',
            ratio: max > 0 ? platos[i].cantidadTotal / max : 0,
            color: _verde,
          ),
      ],
    );
  }

  static pw.Widget _graficaBarrasTiempos(List<TiempoMedioPlato> tiempos) {
    final max = tiempos
        .map((t) => t.tiempoMedioMinutos)
        .reduce((a, b) => a > b ? a : b);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final t in tiempos)
          _barra(
            etiqueta: t.nombreProducto,
            valorTexto: '${t.tiempoMedioMinutos.toStringAsFixed(1)} min',
            ratio: max > 0 ? t.tiempoMedioMinutos / max : 0,
            color: _naranja,
          ),
      ],
    );
  }

  static pw.Widget _barra({
    required String etiqueta,
    required String valorTexto,
    required double ratio,
    required PdfColor color,
  }) {
    final factor = ratio.clamp(0.0, 1.0);
    final flexBarra = (factor * 100).round().clamp(1, 100);
    final flexResto = 100 - flexBarra;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              etiqueta,
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: flexBarra,
                  child: pw.Container(
                    height: 12,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                if (flexResto > 0)
                  pw.Expanded(
                    flex: flexResto,
                    child: pw.Container(
                      height: 12,
                      color: _grisClaro,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 48,
            child: pw.Text(
              valorTexto,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _celda(
    String texto, {
    bool negrita = false,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          texto,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _tablaPlatos(List<PlatoMasPedido> platos) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _grisClaro),
          children: [
            _celda('#', negrita: true, align: pw.Alignment.center),
            _celda('Plato', negrita: true),
            _celda('Categoría', negrita: true),
            _celda('Cantidad', negrita: true, align: pw.Alignment.centerRight),
          ],
        ),
        ...platos.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return pw.TableRow(
            children: [
              _celda('${i + 1}', align: pw.Alignment.center),
              _celda(p.nombreProducto),
              _celda(p.categoria?.isNotEmpty == true ? p.categoria! : '—'),
              _celda('${p.cantidadTotal}', align: pw.Alignment.centerRight),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tablaTiempos(List<TiempoMedioPlato> tiempos) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _grisClaro),
          children: [
            _celda('Plato', negrita: true),
            _celda('Registros', negrita: true, align: pw.Alignment.center),
            _celda(
              'Media (min)',
              negrita: true,
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
        ...tiempos.map(
          (t) => pw.TableRow(
            children: [
              _celda(t.nombreProducto),
              _celda('${t.cantidadRegistros}', align: pw.Alignment.center),
              _celda(
                t.tiempoMedioMinutos.toStringAsFixed(1),
                align: pw.Alignment.centerRight,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
