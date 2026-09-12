/// Extrae un precio en euros desde texto libre (portapapeles o página).
double? extraerPrecioEuros(String? texto) {
  if (texto == null) return null;
  final t = texto.trim();
  if (t.isEmpty) return null;

  final patterns = <RegExp>[
    RegExp(r'(?:€|EUR|euro[s]?)\s*(\d{1,5}(?:[.,]\d{1,2})?)', caseSensitive: false),
    RegExp(r'(\d{1,5}(?:[.,]\d{1,2})?)\s*(?:€|EUR|euro[s]?)', caseSensitive: false),
    RegExp(r'^(\d{1,5}[.,]\d{2})$'),
  ];

  for (final re in patterns) {
    final m = re.firstMatch(t);
    if (m != null) {
      final raw = m.group(1)!.replaceAll(',', '.');
      final v = double.tryParse(raw);
      if (v != null && v > 0 && v < 100000) return v;
    }
  }
  return null;
}
