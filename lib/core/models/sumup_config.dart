/// Configuración de la integración SumUp Terminal (Cloud API).
class SumUpConfig {
  final String apiKey;
  final String merchantCode;
  final String readerId;
  final String affiliateAppId;
  final String currency;
  final bool activo;
  /// URL base (producción por defecto).
  final String apiBaseUrl;

  const SumUpConfig({
    this.apiKey = '',
    this.merchantCode = '',
    this.readerId = '',
    this.affiliateAppId = '',
    this.currency = 'EUR',
    this.activo = false,
    this.apiBaseUrl = 'https://api.sumup.com',
  });

  bool get estaCompleta =>
      activo &&
      apiKey.isNotEmpty &&
      merchantCode.isNotEmpty &&
      readerId.isNotEmpty &&
      affiliateAppId.isNotEmpty;

  factory SumUpConfig.fromJson(Map<String, dynamic> json) => SumUpConfig(
        apiKey: json['apiKey'] as String? ?? '',
        merchantCode: json['merchantCode'] as String? ?? '',
        readerId: json['readerId'] as String? ?? '',
        affiliateAppId: json['affiliateAppId'] as String? ?? '',
        currency: json['currency'] as String? ?? 'EUR',
        activo: json['activo'] as bool? ?? false,
        apiBaseUrl: json['apiBaseUrl'] as String? ?? 'https://api.sumup.com',
      );

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'merchantCode': merchantCode,
        'readerId': readerId,
        'affiliateAppId': affiliateAppId,
        'currency': currency,
        'activo': activo,
        'apiBaseUrl': apiBaseUrl,
      };
}
