import 'dart:convert';
import 'package:http/http.dart' as http;

/// ConversionResult holds a successful conversion result.
class ConversionResult {
  final double result;
  final String unit;
  final String formula;

  const ConversionResult({
    required this.result,
    required this.unit,
    required this.formula,
  });
}

/// TempConvService communicates with the Go backend via the REST/HTTP gateway.
///
/// The backend exposes the gRPC-Gateway at:
///   POST /v1/celsius-to-fahrenheit  body: {"value": <double>}
///   POST /v1/fahrenheit-to-celsius  body: {"value": <double>}
///
/// We use plain HTTP/JSON because gRPC-Web requires an Envoy proxy in the
/// browser environment. The HTTP gateway provides the same functionality.
class TempConvService {
  final String baseUrl;
  final http.Client _client;

  TempConvService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Convert [celsius] to Fahrenheit.
  Future<ConversionResult> celsiusToFahrenheit(double celsius) async {
    return _convert('/tempconv.TempConverter/CelsiusToFahrenheit', celsius);
  }

  /// Convert [fahrenheit] to Celsius.
  Future<ConversionResult> fahrenheitToCelsius(double fahrenheit) async {
    return _convert('/tempconv.TempConverter/FahrenheitToCelsius', fahrenheit);
  }

  Future<ConversionResult> _convert(String path, double value) async {
    final uri = Uri.parse('$baseUrl$path');
    final body = jsonEncode({'value': value});

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['message'] as String? ?? 'Unknown error';
      throw TempConvException('Server error ${response.statusCode}: $message');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ConversionResult(
      result: (data['result'] as num).toDouble(),
      unit: data['unit'] as String? ?? '',
      formula: data['formula'] as String? ?? '',
    );
  }

  void dispose() => _client.close();
}

/// Thrown when the backend returns an error.
class TempConvException implements Exception {
  final String message;
  const TempConvException(this.message);

  @override
  String toString() => 'TempConvException: $message';
}
