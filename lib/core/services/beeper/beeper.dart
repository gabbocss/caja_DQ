/// Export condicional del "beeper" (solo suena en Web).
library;

export 'beeper_stub.dart'
    if (dart.library.html) 'beeper_web.dart';

