import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/platform_utils.dart';

/// Abre la ficha del proveedor en una ventana de navegador dedicada.
///
/// Usa modo `--app` con un perfil persistente para conservar el login de Metro
/// entre sesiones. Si no hay navegador compatible, cae a [launchUrl].
class ProveedorBrowserService {
  ProveedorBrowserService._();

  static Future<Directory> _perfilDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}metro_browser_profile');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<bool> abrir(String urlRaw) async {
    final url = urlRaw.trim();
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }

    if (PlatformUtils.isDesktop && !kIsWeb) {
      final ok = await _abrirModoApp(uri);
      if (ok) return true;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> _abrirModoApp(Uri uri) async {
    final perfil = await _perfilDir();
    final perfilPath = perfil.path;
    final candidates = <List<String>>[];

    if (PlatformUtils.isWindows) {
      candidates.addAll([
        [
          'cmd',
          '/c',
          'start',
          '',
          'msedge',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
        [
          'cmd',
          '/c',
          'start',
          '',
          'chrome',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
      ]);
    } else if (PlatformUtils.isLinux) {
      candidates.addAll([
        [
          'google-chrome',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
        [
          'chromium',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
        [
          'chromium-browser',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
        [
          'microsoft-edge',
          '--app=${uri.toString()}',
          '--user-data-dir=$perfilPath',
        ],
      ]);
    } else if (PlatformUtils.isMacOS) {
      candidates.add([
        'open',
        '-na',
        'Google Chrome',
        '--args',
        '--app=${uri.toString()}',
        '--user-data-dir=$perfilPath',
      ]);
    }

    for (final args in candidates) {
      try {
        final executable = args.first;
        final rest = args.sublist(1);
        final result = await Process.start(
          executable,
          rest,
          mode: ProcessStartMode.detached,
        );
        // Si arranca el proceso, damos por bueno (no esperamos exit).
        debugPrint('ProveedorBrowserService: lanzado $executable (pid ${result.pid})');
        return true;
      } catch (e) {
        debugPrint('ProveedorBrowserService: fallo $args → $e');
      }
    }
    return false;
  }
}
