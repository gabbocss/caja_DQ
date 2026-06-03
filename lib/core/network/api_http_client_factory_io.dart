import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Host del servidor central 24/7 (certificado autofirmado en IP pública).
const String kServidorCentralReservasHost = '64.227.113.139';

/// Hosts HTTPS en los que se acepta certificado no firmado por una CA pública.
Set<String> hostsHttpsConCertificadoPermitido(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  final hosts = <String>{kServidorCentralReservasHost};
  if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
    hosts.add(uri.host);
  }
  return hosts;
}

/// Cliente HTTP con bypass TLS solo para el servidor central y el host de [baseUrl].
http.Client createApiHttpClient(String baseUrl) {
  final hostsPermitidos = hostsHttpsConCertificadoPermitido(baseUrl);
  final ioHttp = HttpClient();
  ioHttp.badCertificateCallback =
      (X509Certificate cert, String host, int port) {
    return hostsPermitidos.contains(host);
  };
  return IOClient(ioHttp);
}
