///
//  Generated code. Do not modify.
//  source: tempconv.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'tempconv.pb.dart' as $0;

export 'tempconv.pb.dart';

@$pb.GrpcServiceName('tempconv.TempConverter')
class TempConverterClient extends $grpc.Client {
  static final _$celsiusToFahrenheit =
      $grpc.ClientMethod<$0.ConversionRequest, $0.ConversionResponse>(
    '/tempconv.TempConverter/CelsiusToFahrenheit',
    ($0.ConversionRequest value) => value.writeToBuffer(),
    ($core.List<$core.int> value) => $0.ConversionResponse.fromBuffer(value),
  );

  static final _$fahrenheitToCelsius =
      $grpc.ClientMethod<$0.ConversionRequest, $0.ConversionResponse>(
    '/tempconv.TempConverter/FahrenheitToCelsius',
    ($0.ConversionRequest value) => value.writeToBuffer(),
    ($core.List<$core.int> value) => $0.ConversionResponse.fromBuffer(value),
  );

  TempConverterClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.ConversionResponse> celsiusToFahrenheit(
      $0.ConversionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$celsiusToFahrenheit, request, options: options);
  }

  $grpc.ResponseFuture<$0.ConversionResponse> fahrenheitToCelsius(
      $0.ConversionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$fahrenheitToCelsius, request, options: options);
  }
}
