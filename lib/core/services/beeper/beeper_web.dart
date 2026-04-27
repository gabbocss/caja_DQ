import 'dart:async';
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Beeper simple para Flutter Web usando Web Audio API.
///
/// Nota: los navegadores suelen exigir interacción del usuario antes de permitir audio.
class Beeper {
  web.AudioContext? _ctx;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> enable() async {
    _enabled = true;
    _ctx ??= web.AudioContext();
    // "Desbloqueo" típico: resume del contexto en gesto de usuario.
    try {
      await _ctx!.resume().toDart;
      // Pequeño beep silencioso para calentar (no molestar).
      await beep(volume: 0.0);
    } catch (_) {
      // Si el navegador bloquea, no hacemos nada; se reintenta en el próximo gesto.
    }
  }

  Future<void> disable() async {
    _enabled = false;
  }

  Future<void> beep({
    double frequencyHz = 880.0,
    int durationMs = 140,
    double volume = 0.2,
  }) async {
    if (!_enabled) return;
    _ctx ??= web.AudioContext();

    try {
      await _ctx!.resume().toDart;
    } catch (_) {
      // Bloqueado por autoplay policy.
      return;
    }

    final ctx = _ctx!;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.value = frequencyHz;
    gain.gain.value = volume.clamp(0.0, 1.0);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(0);
    // Stop programado para evitar leaks.
    osc.stop(ctx.currentTime + (durationMs / 1000));

    // Esperar aproximadamente a que termine para no solapar en llamadas rápidas.
    await Future<void>.delayed(Duration(milliseconds: durationMs));
  }
}

