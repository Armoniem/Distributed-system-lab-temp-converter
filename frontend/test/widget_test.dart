import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tempconv_frontend/main.dart';
import 'package:tempconv_frontend/services/temp_conv_service.dart';

/// Fake HTTP client that returns a pre-programmed response for tests.
class _FakeHttpClient extends http.BaseClient {
  final http.Response fakeResponse;
  _FakeHttpClient(this.fakeResponse);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(fakeResponse.bodyBytes),
      fakeResponse.statusCode,
      headers: fakeResponse.headers,
    );
  }
}

void main() {
  testWidgets('App renders TempConv title', (WidgetTester tester) async {
    final fakeClient = _FakeHttpClient(
      http.Response(
        '{"result":32.0,"unit":"Fahrenheit","formula":"(0°C × 9/5) + 32 = 32°F"}',
        200,
      ),
    );
    final service = TempConvService(
      baseUrl: 'http://localhost:8080',
      client: fakeClient,
    );

    await tester.pumpWidget(TempConvApp(service: service));
    await tester.pump();

    expect(find.text('TempConv'), findsOneWidget);
  });

  testWidgets('App has Convert button', (WidgetTester tester) async {
    final fakeClient = _FakeHttpClient(
      http.Response(
        '{"result":212.0,"unit":"Fahrenheit","formula":"test"}',
        200,
      ),
    );
    final service = TempConvService(
      baseUrl: 'http://localhost:8080',
      client: fakeClient,
    );

    await tester.pumpWidget(TempConvApp(service: service));
    await tester.pump();

    // Should find a button with "Convert" in the label
    expect(find.byKey(const Key('convert_button')), findsOneWidget);
  });

  testWidgets('Convert button triggers conversion', (
    WidgetTester tester,
  ) async {
    final fakeClient = _FakeHttpClient(
      http.Response(
        '{"result":212.0,"unit":"Fahrenheit","formula":"(100.0000 °C × 9/5) + 32 = 212.000000 °F"}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final service = TempConvService(
      baseUrl: 'http://localhost:8080',
      client: fakeClient,
    );

    await tester.pumpWidget(TempConvApp(service: service));
    await tester.pump();

    // Enter a value
    await tester.enterText(find.byKey(const Key('temperature_input')), '100');
    await tester.pump();

    // Tap convert
    await tester.tap(find.byKey(const Key('convert_button')));
    await tester.pump(); // loading state
    await tester.pump(const Duration(milliseconds: 100)); // response arrives

    // Result should now show
    expect(find.text('212.0000'), findsOneWidget);
  });
}
