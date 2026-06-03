import 'package:http/http.dart' as http;

/// En Web no hay [HttpClient.badCertificateCallback]; el navegador valida TLS.
http.Client createApiHttpClient(String baseUrl) => http.Client();
