// ignore_for_file: avoid_print
/// Build completo de la app web (cocina) sin dejar el proyecto roto para desktop.
///
/// Ejecuta en orden:
/// 1. Parchea los .g.dart para que compilen en JavaScript
/// 2. flutter build web
/// 3. Regenera los .g.dart para Windows/Linux (build_runner)
///
/// Uso: dart run tool/build_web.dart
///
/// Después puedes ejecutar la app de escritorio con normalidad y la carpeta
/// build/web queda lista para servir o empaquetar con el .exe.

import 'dart:io';

void main() async {
  final projectRoot = Directory.current.path;
  print('═══════════════════════════════════════════════════════════════');
  print('  Build Web (cocina) - deja .g.dart listos para desktop después');
  print('═══════════════════════════════════════════════════════════════');
  print('');

  // 1. Parche para web
  print('1/3 Parcheando .g.dart para web...');
  var result = await Process.run(
    'dart',
    ['run', 'tool/patch_g_for_web.dart'],
    workingDirectory: projectRoot,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    print(result.stderr);
    exit(1);
  }
  print('');

  // 2. Flutter build web
  print('2/3 Ejecutando flutter build web...');
  result = await Process.run(
    'flutter',
    ['build', 'web'],
    workingDirectory: projectRoot,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }
  print('');

  // 3. Restaurar .g.dart para desktop (borrar los parcheados y regenerar)
  print('3/3 Regenerando .g.dart para Windows/Linux...');
  final modelsDir = Directory('$projectRoot/lib/core/models');
  if (modelsDir.existsSync()) {
    for (final f in modelsDir.listSync()) {
      if (f.path.endsWith('.g.dart')) {
        (f as File).deleteSync();
      }
    }
  }
  result = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: projectRoot,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }

  print('');
  print('✅ Listo. build/web está actualizado y los .g.dart son válidos para desktop.');
  print('   Puedes ejecutar la app en Windows/Linux con normalidad.');
  print('');
}
