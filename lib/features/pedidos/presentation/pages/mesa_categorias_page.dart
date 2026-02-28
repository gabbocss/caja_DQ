import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/core.dart';

/// Pantalla de categorías para una mesa.
/// Muestra la lista de categorías (Bebidas, Primeros, etc.); al tocar una se navega a platos.
/// A la derecha se muestra el QR de la mesa para pedir buffet desde el móvil del cliente.
class MesaCategoriasPage extends StatefulWidget {
  final int numeroMesa;

  const MesaCategoriasPage({super.key, required this.numeroMesa});

  @override
  State<MesaCategoriasPage> createState() => _MesaCategoriasPageState();
}

class _MesaCategoriasPageState extends State<MesaCategoriasPage> {
  List<String> _categorias = [];
  bool _cargando = true;
  String? _qrUrl;
  bool _qrCargando = true;
  String? _qrError;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarUrlQr();
  }

  Future<void> _cargarUrlQr() async {
    setState(() {
      _qrCargando = true;
      _qrError = null;
    });
    try {
      String url;
      if (sl.isRegistered<ApiClient>()) {
        url = await sl<ApiClient>().obtenerUrlQrMesa(widget.numeroMesa);
      } else {
        final baseUrl = _obtenerBaseUrlServidor();
        final token = await DatabaseService.instance.getQrTokenForMesa(widget.numeroMesa);
        url = '$baseUrl/qr/$token';
      }
      if (mounted) setState(() {
        _qrUrl = url;
        _qrCargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar URL QR: $e');
      if (mounted) setState(() {
        _qrError = e.toString();
        _qrCargando = false;
      });
    }
  }

  String _obtenerBaseUrlServidor() {
    if (sl.isRegistered<LocalServer>() && LocalServer.instance.serverUrl != null) {
      final url = LocalServer.instance.serverUrl!;
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
    final base = serverUrl ?? 'http://localhost:8080';
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    try {
      List<String> cats;
      if (sl.isRegistered<ApiClient>()) {
        final list = await sl<ApiClient>().obtenerCategorias();
        cats = list.map((c) => c.nombre).toList();
      } else {
        final list = await DatabaseService.instance.obtenerCategorias();
        cats = list.map((c) => c.nombre).toList();
      }
      if (mounted) setState(() {
        _categorias = cats.isNotEmpty ? cats : CategoriaProducto.todas;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
      if (mounted) setState(() {
        _categorias = CategoriaProducto.todas;
        _cargando = false;
      });
    }
  }

  static IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case CategoriaProducto.tacos:
        return Icons.lunch_dining;
      case CategoriaProducto.antojitos:
        return Icons.tapas;
      case CategoriaProducto.platosFuertes:
        return Icons.dinner_dining;
      case CategoriaProducto.sopas:
        return Icons.soup_kitchen;
      case CategoriaProducto.ensaladas:
        return Icons.eco;
      case CategoriaProducto.postres:
        return Icons.cake;
      case CategoriaProducto.bebidas:
        return Icons.local_drink;
      case CategoriaProducto.bebidasAlcoholicas:
        return Icons.local_bar;
      case CategoriaProducto.extras:
        return Icons.add_circle;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Mesa ${widget.numeroMesa} - Categorías'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];
                      final slug = categoria.replaceAll(' ', '_');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/mesas/${widget.numeroMesa}/platos/$slug'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0F3460), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE94560).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconoCategoria(categoria),
                                      color: const Color(0xFFE94560),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      categoria,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white54, size: 28),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SingleChildScrollView(
                  child: _buildQrCard(),
                ),
              ],
            ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D9A5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, color: Color(0xFF00D9A5), size: 24),
          const SizedBox(height: 8),
          Text(
            'QR buffet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Mesa ${widget.numeroMesa}',
            style: const TextStyle(
              color: Color(0xFF00D9A5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_qrCargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(color: Color(0xFF00D9A5)),
              ),
            )
          else if (_qrError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No disponible',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            )
          else if (_qrUrl != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: _qrUrl!,
                version: QrVersions.auto,
                size: 140,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1A1A2E),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
