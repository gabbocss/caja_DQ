// ignore_for_file: avoid_print
/// Parchea los .g.dart de Isar para que compilen a JavaScript:
/// reemplaza enteros fuera del rango seguro de JS (2^53) por 0.
///
/// Uso: dart run tool/patch_g_for_web.dart
/// Luego: flutter build web

import 'dart:io';

const safeMax = 9007199254740992; // 2^53

void main() {
  final dir = Directory('lib/core/models');
  if (!dir.existsSync()) {
    print('No se encontró lib/core/models');
    exit(1);
  }

  for (final f in dir.listSync()) {
    if (f.path.endsWith('.g.dart')) {
      patchFile(File(f.path));
    }
  }

  print('');
  print('Listo. Siguiente paso: flutter build web');
  print('');
  print('Después del build web, regenera los .g.dart para desktop/móvil:');
  print('  dart run build_runner build --delete-conflicting-outputs');
}

void patchFile(File file) {
  var content = file.readAsStringSync();
  final original = content;

  // Reemplazar literales enteros fuera del rango seguro
  content = content.replaceAllMapped(
    RegExp(r'\bid:\s*(-?\d+)\b'),
    (m) {
      final n = int.tryParse(m.group(1)!);
      if (n == null) return m.group(0)!;
      if (n > safeMax || n < -safeMax) return 'id: 0';
      return m.group(0)!;
    },
  );

  if (content != original) {
    file.writeAsStringSync(content);
    print('Parcheado: ${file.path}');
  }
}
