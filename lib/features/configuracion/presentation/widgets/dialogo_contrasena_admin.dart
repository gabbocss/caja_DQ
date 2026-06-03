import 'package:flutter/material.dart';

import '../../../../core/constants/admin_config_constants.dart';

/// Diálogo que exige la contraseña de administrador antes de ajustes críticos.
class DialogoContrasenaAdmin extends StatefulWidget {
  const DialogoContrasenaAdmin({super.key});

  @override
  State<DialogoContrasenaAdmin> createState() => _DialogoContrasenaAdminState();
}

class _DialogoContrasenaAdminState extends State<DialogoContrasenaAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaCtrl = TextEditingController();
  bool _oculta = true;

  @override
  void dispose() {
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  void _verificar() {
    if (!_formKey.currentState!.validate()) return;
    final ingresada = _contrasenaCtrl.text.trim();
    if (ingresada != kContrasenaAdminPorDefecto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acceso denegado. Contraseña de administrador incorrecta.',
          ),
          backgroundColor: Color(0xFFE94560),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFFE94560), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Acceso de administrador',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Introduce la contraseña de administrador para continuar.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contrasenaCtrl,
              obscureText: _oculta,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF00D9A5)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _oculta ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => _oculta = !_oculta),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0F3460)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00D9A5)),
                ),
              ),
              onFieldSubmitted: (_) => _verificar(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Introduce la contraseña';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _verificar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9A5),
            foregroundColor: const Color(0xFF1A1A2E),
          ),
          child: const Text('Acceder'),
        ),
      ],
    );
  }
}
