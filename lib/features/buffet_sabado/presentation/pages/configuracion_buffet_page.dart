import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// Página de configuración del servicio de Buffet
/// 
/// Permite editar horarios, precios y reglas del "All You Can Eat"
class ConfiguracionBuffetPage extends StatefulWidget {
  const ConfiguracionBuffetPage({super.key});

  @override
  State<ConfiguracionBuffetPage> createState() => _ConfiguracionBuffetPageState();
}

class _ConfiguracionBuffetPageState extends State<ConfiguracionBuffetPage> {
  final _formKey = GlobalKey<FormState>();
  ConfiguracionBuffet? _config;
  bool _cargando = true;
  bool _guardando = false;

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioAdultoController;
  late TextEditingController _precioNinoController;
  late TextEditingController _precioMenorController;
  late TextEditingController _precioCubiertoController;
  late TextEditingController _edadMinimaController;
  late TextEditingController _edadMaximaController;
  late TextEditingController _mensajeController;
  late TextEditingController _impresoraBuffetIpController;
  late TextEditingController _impresoraBuffetPuertoController;

  // Estado
  int _diaSemana = DateTime.saturday;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 11, minute: 30);
  TimeOfDay _horaFin = const TimeOfDay(hour: 14, minute: 45);
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _cargarConfiguracion();
  }

  void _inicializarControllers() {
    _nombreController = TextEditingController();
    _descripcionController = TextEditingController();
    _precioAdultoController = TextEditingController();
    _precioNinoController = TextEditingController();
    _precioMenorController = TextEditingController();
    _precioCubiertoController = TextEditingController();
    _edadMinimaController = TextEditingController();
    _edadMaximaController = TextEditingController();
    _mensajeController = TextEditingController();
    _impresoraBuffetIpController = TextEditingController();
    _impresoraBuffetPuertoController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioAdultoController.dispose();
    _precioNinoController.dispose();
    _precioMenorController.dispose();
    _precioCubiertoController.dispose();
    _edadMinimaController.dispose();
    _edadMaximaController.dispose();
    _mensajeController.dispose();
    _impresoraBuffetIpController.dispose();
    _impresoraBuffetPuertoController.dispose();
    super.dispose();
  }

  /// Evita mostrar NaN en precios (valores no inicializados o corruptos)
  String _precioParaTexto(double value, double fallback) {
    if (value.isNaN || value.isInfinite || value < 0) return fallback.toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  double _parsearPrecio(String text, double fallback) {
    final v = double.tryParse(text.replaceAll(',', '.'));
    if (v == null || v.isNaN || v.isInfinite || v < 0) return fallback;
    return v;
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await DatabaseService.instance.obtenerConfiguracionBuffetActiva();
      if (config != null) {
        _config = config;
        _nombreController.text = config.nombre;
        _descripcionController.text = config.descripcion ?? '';
        _precioAdultoController.text = _precioParaTexto(config.precioAdulto, 18.0);
        _precioNinoController.text = _precioParaTexto(config.precioNino, 9.0);
        _precioMenorController.text = _precioParaTexto(config.precioMenor, 0.0);
        _precioCubiertoController.text = _precioParaTexto(config.precioCubierto, 2.0);
        _edadMinimaController.text = config.edadMinimaInfantil.toString();
        _edadMaximaController.text = config.edadMaximaInfantil.toString();
        _mensajeController.text = config.mensajePromocion ?? '';
        _impresoraBuffetIpController.text = config.impresoraBuffetIp ?? '';
        _impresoraBuffetPuertoController.text =
            config.impresoraBuffetPuerto?.toString() ?? '9100';
        _diaSemana = config.diaSemana ?? DateTime.saturday;
        _activo = config.activo;
        
        // Parsear horas
        final partsInicio = config.horaInicio.split(':');
        _horaInicio = TimeOfDay(
          hour: int.parse(partsInicio[0]),
          minute: int.parse(partsInicio[1]),
        );
        final partsFin = config.horaFin.split(':');
        _horaFin = TimeOfDay(
          hour: int.parse(partsFin[0]),
          minute: int.parse(partsFin[1]),
        );
      } else {
        // Valores por defecto
        _nombreController.text = 'Buffet Sábado';
        _descripcionController.text = 'All You Can Eat - Sábados';
        _precioAdultoController.text = '18.00';
        _precioNinoController.text = '9.00';
        _precioMenorController.text = '0.00';
        _precioCubiertoController.text = '2.00';
        _edadMinimaController.text = '6';
        _edadMaximaController.text = '10';
        _mensajeController.text = '¡Buffet All You Can Eat!';
        _impresoraBuffetIpController.text = '';
        _impresoraBuffetPuertoController.text = '9100';
      }
    } catch (e) {
      debugPrint('Error al cargar configuración: $e');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final config = _config ?? ConfiguracionBuffet();
      
      config.nombre = _nombreController.text;
      config.descripcion = _descripcionController.text;
      config.precioAdulto = _parsearPrecio(_precioAdultoController.text, 18.0);
      config.precioNino = _parsearPrecio(_precioNinoController.text, 9.0);
      config.precioMenor = _parsearPrecio(_precioMenorController.text, 0.0);
      config.precioCubierto = _parsearPrecio(_precioCubiertoController.text, 2.0);
      config.edadMinimaInfantil = int.parse(_edadMinimaController.text);
      config.edadMaximaInfantil = int.parse(_edadMaximaController.text);
      config.mensajePromocion = _mensajeController.text;
      config.diaSemana = _diaSemana;
      config.horaInicio = '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}';
      config.horaFin = '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}';
      config.activo = _activo;
      config.colorTema = '#FFD700';
      final ipBuf = _impresoraBuffetIpController.text.trim();
      config.impresoraBuffetIp = ipBuf.isEmpty ? null : ipBuf;
      config.impresoraBuffetPuerto =
          int.tryParse(_impresoraBuffetPuertoController.text.trim()) ?? 9100;
      config.fechaCreacion = _config?.fechaCreacion ?? DateTime.now();

      await DatabaseService.instance.guardarConfiguracionBuffet(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: Color(0xFF00D9A5),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  String _nombreDia(int dia) {
    switch (dia) {
      case DateTime.monday: return 'Lunes';
      case DateTime.tuesday: return 'Martes';
      case DateTime.wednesday: return 'Miércoles';
      case DateTime.thursday: return 'Jueves';
      case DateTime.friday: return 'Viernes';
      case DateTime.saturday: return 'Sábado';
      case DateTime.sunday: return 'Domingo';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: Color(0xFFFFD700)),
            SizedBox(width: 12),
            Text(
              'CONFIGURACIÓN BUFFET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Indicador de estado activo
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text(
                  'Activo',
                  style: TextStyle(color: Colors.white70),
                ),
                Switch(
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
                  activeTrackColor: const Color(0xFFFFD700),
                  thumbColor: WidgetStateProperty.all(Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner informativo
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // Sección: Información básica
              _buildSeccion(
                titulo: 'Información Básica',
                icono: Icons.info_outline,
                children: [
                  _buildCampoTexto(
                    controller: _nombreController,
                    label: 'Nombre del servicio',
                    hint: 'Ej: Buffet Sábado',
                    icono: Icons.label,
                  ),
                  const SizedBox(height: 16),
                  _buildCampoTexto(
                    controller: _descripcionController,
                    label: 'Descripción',
                    hint: 'Ej: All You Can Eat - Sábados',
                    icono: Icons.description,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildCampoTexto(
                    controller: _mensajeController,
                    label: 'Mensaje promocional',
                    hint: 'Mensaje para mostrar en la UI',
                    icono: Icons.campaign,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Horario
              _buildSeccion(
                titulo: 'Horario',
                icono: Icons.schedule,
                children: [
                  // Selector de día
                  _buildSelectorDia(),
                  const SizedBox(height: 16),
                  // Selectores de hora
                  Row(
                    children: [
                      Expanded(child: _buildSelectorHora('Hora inicio', _horaInicio, (t) => setState(() => _horaInicio = t))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSelectorHora('Hora fin', _horaFin, (t) => setState(() => _horaFin = t))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Precios
              _buildSeccion(
                titulo: 'Precios',
                icono: Icons.euro,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCampoPrecio(
                          controller: _precioAdultoController,
                          label: 'Adultos',
                          color: const Color(0xFFE94560),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCampoPrecio(
                          controller: _precioNinoController,
                          label: 'Niños',
                          color: const Color(0xFF00D9A5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCampoPrecio(
                          controller: _precioMenorController,
                          label: 'Menores',
                          color: const Color(0xFF9B59B6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Cubiertos (fuera de horario buffet)
              _buildSeccion(
                titulo: 'Cubiertos (fuera de horario buffet)',
                icono: Icons.restaurant,
                children: [
                  _buildCampoPrecio(
                    controller: _precioCubiertoController,
                    label: 'Precio por cubierto (€)',
                    color: const Color(0xFF0F3460),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se usará cuando el cliente abra mesa fuera del horario de buffet.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Impresora Buffet
              _buildSeccion(
                titulo: 'Impresora Buffet (Hecho Todo / Hecho Parcial)',
                icono: Icons.print,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCampoTexto(
                          controller: _impresoraBuffetIpController,
                          label: 'IP impresora',
                          hint: 'Ej: 192.168.1.100',
                          icono: Icons.computer,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[^\d.]')),
                          ],
                          validator: (_) => null, // opcional
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCampoTexto(
                          controller: _impresoraBuffetPuertoController,
                          label: 'Puerto',
                          hint: '9100',
                          icono: Icons.numbers,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (_) => null, // opcional
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opcional. Impresora usada al marcar Hecho (Todo) o Hecho (Parcial) en modo Buffet. Si está vacía, se usa la impresora del destino.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Edades
              _buildSeccion(
                titulo: 'Rangos de Edad',
                icono: Icons.people,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCampoNumero(
                          controller: _edadMinimaController,
                          label: 'Edad mínima (niños)',
                          hint: '6',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCampoNumero(
                          controller: _edadMaximaController,
                          label: 'Edad máxima (niños)',
                          hint: '10',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen de precios:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildResumenPrecio('Menores de ${_edadMinimaController.text.isEmpty ? '6' : _edadMinimaController.text} años', _precioMenorController.text),
                        _buildResumenPrecio('Niños (${_edadMinimaController.text.isEmpty ? '6' : _edadMinimaController.text}-${_edadMaximaController.text.isEmpty ? '10' : _edadMaximaController.text} años)', _precioNinoController.text),
                        _buildResumenPrecio('Adultos (+${_edadMaximaController.text.isEmpty ? '10' : _edadMaximaController.text} años)', _precioAdultoController.text),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarConfiguracion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black87,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.black87),
                            SizedBox(width: 12),
                            Text(
                              'GUARDAR CONFIGURACIÓN',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final ahora = DateTime.now();
    final esHorario = _config?.esHorarioBuffet() ?? false;
    final esDiaCorrecto = ahora.weekday == _diaSemana;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: esHorario
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF16213E), const Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: esHorario
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            esHorario ? Icons.restaurant : Icons.schedule,
            color: esHorario ? Colors.black87 : Colors.white70,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esHorario ? '¡BUFFET ACTIVO!' : 'Buffet programado',
                  style: TextStyle(
                    color: esHorario ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  esDiaCorrecto
                      ? esHorario
                          ? 'El servicio de buffet está actualmente en curso'
                          : 'Hoy es ${_nombreDia(_diaSemana)}, horario: ${_horaInicio.format(context)} - ${_horaFin.format(context)}'
                      : 'Próximo buffet: ${_nombreDia(_diaSemana)} de ${_horaInicio.format(context)} a ${_horaFin.format(context)}',
                  style: TextStyle(
                    color: esHorario ? Colors.black54 : Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (esHorario)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'EN VIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0F3460),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Text(
                titulo.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icono,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? ((value) => value?.isEmpty ?? true ? 'Campo requerido' : null),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: icono != null ? Icon(icono, color: Colors.white54) : null,
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
      ),
    );
  }

  Widget _buildCampoPrecio({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: '€',
            suffixStyle: TextStyle(color: color, fontSize: 18),
            filled: true,
            fillColor: const Color(0xFF0F3460),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Requerido';
            if (double.tryParse(value!) == null) return 'Inválido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoNumero({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Requerido';
        if (int.tryParse(value!) == null) return 'Inválido';
        return null;
      },
    );
  }

  Widget _buildSelectorDia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Día de la semana',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var dia = DateTime.monday; dia <= DateTime.sunday; dia++)
              _DiaChip(
                dia: dia,
                nombre: _nombreDia(dia),
                seleccionado: _diaSemana == dia,
                onTap: () => setState(() => _diaSemana = dia),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorHora(String label, TimeOfDay hora, ValueChanged<TimeOfDay> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final seleccionada = await showTimePicker(
              context: context,
              initialTime: hora,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFFFD700),
                      surface: Color(0xFF16213E),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (seleccionada != null) {
              onChanged(seleccionada);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  hora.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenPrecio(String descripcion, String precio) {
    final precioNum = double.tryParse(precio) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            descripcion,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            precioNum > 0 ? '${precioNum.toStringAsFixed(0)}€' : 'GRATIS',
            style: TextStyle(
              color: precioNum > 0 ? const Color(0xFF00D9A5) : const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip para seleccionar día de la semana
class _DiaChip extends StatelessWidget {
  final int dia;
  final String nombre;
  final bool seleccionado;
  final VoidCallback onTap;

  const _DiaChip({
    required this.dia,
    required this.nombre,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFFFD700) : const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? const Color(0xFFFFD700) : const Color(0xFF16213E),
            width: 2,
          ),
        ),
        child: Text(
          nombre.substring(0, 3).toUpperCase(),
          style: TextStyle(
            color: seleccionado ? Colors.black87 : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
