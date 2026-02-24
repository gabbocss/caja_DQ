// ignore_for_file: avoid_print
/// Copia la app web (build/web) junto al ejecutable de Windows para distribución.
/// Así el .exe encuentra la carpeta "web" al lado y sirve la UI cocina sin Flutter en el PC destino.
///
/// Uso (después de haber ejecutado flutter build web y flutter build windows):
///   dart run tool/package_windows_with_web.dart
///
/// Luego copia toda la carpeta build/windows/.../Release (incluye .exe + web/) al PC destino.

import 'dart:io';

void main() {
  final projectRoot = Directory.current.path;
  final buildWeb = Directory(projectRoot + '/build/web');
  if (!buildWeb.existsSync()) {
    print('❌ No existe build/web. Ejecuta antes:');
    print('   dart run tool/patch_g_for_web.dart');
    print('   flutter build web');
    exit(1);
  }
  if (!File('${buildWeb.path}/index.html').existsSync()) {
    print('❌ build/web no contiene index.html. Ejecuta "flutter build web".');
    exit(1);
  }

  // Flutter 3.16+: build/windows/x64/runner/Release; anterior: build/windows/runner/Release
  final candidates = [
    '$projectRoot/build/windows/x64/runner/Release',
    '$projectRoot/build/windows/runner/Release',
  ];
  Directory? releaseDir;
  for (final path in candidates) {
    final d = Directory(path);
    if (d.existsSync()) {
      releaseDir = d;
      break;
    }
  }
  if (releaseDir == null) {
    print('❌ No se encontró la carpeta Release de Windows.');
    print('   Ejecuta antes: flutter build windows');
    exit(1);
  }

  final webDest = Directory('${releaseDir.path}/web');
  if (webDest.existsSync()) {
    webDest.deleteSync(recursive: true);
  }
  webDest.createSync(recursive: true);

  print('Copiando build/web → ${releaseDir.path}/web ...');
  _copyDir(buildWeb, webDest);
  print('✅ Listo. Carpeta para distribuir: ${releaseDir.path}');
  print('   (contiene el .exe y la carpeta web con la app cocina)');
}

void _copyDir(Directory source, Directory target) {
  for (final entity in source.listSync()) {
    final name = entity.path.split(Platform.pathSeparator).last;
    final dest = entity is File
        ? File('${target.path}${Platform.pathSeparator}$name')
        : Directory('${target.path}${Platform.pathSeparator}$name');
    if (entity is File) {
      entity.copySync(dest.path);
    } else {
      final destDir = dest as Directory;
      destDir.createSync(recursive: true);
      _copyDir(entity as Directory, destDir);
    }
  }
}
