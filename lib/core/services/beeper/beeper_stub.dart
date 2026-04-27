/// Implementación "no-op" para plataformas no web.
class Beeper {
  const Beeper();

  bool get isEnabled => false;

  Future<void> enable() async {}

  Future<void> disable() async {}

  Future<void> beep() async {}
}

