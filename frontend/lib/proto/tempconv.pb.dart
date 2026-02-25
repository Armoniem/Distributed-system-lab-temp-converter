///
//  Generated code. Do not modify.
//  source: tempconv.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ConversionRequest carries the input temperature value.
class ConversionRequest extends $pb.GeneratedMessage {
  factory ConversionRequest({
    $core.double? value,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }

  ConversionRequest._() : super();

  factory ConversionRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory ConversionRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'ConversionRequest',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'tempconv'),
    createEmptyInstance: create,
  )
    ..a<$core.double>(1, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConversionRequest clone() => ConversionRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConversionRequest copyWith(void Function(ConversionRequest) updates) =>
      super.copyWith((message) => updates(message as ConversionRequest))
          as ConversionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConversionRequest create() => ConversionRequest._();
  ConversionRequest createEmptyInstance() => create();

  @$core.pragma('dart2js:noInline')
  static ConversionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConversionRequest>(create);
  static ConversionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.double v) {
    $_setDouble(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

/// ConversionResponse carries the converted temperature value.
class ConversionResponse extends $pb.GeneratedMessage {
  factory ConversionResponse({
    $core.double? result,
    $core.String? unit,
    $core.String? formula,
  }) {
    final $result = create();
    if (result != null) {
      $result.result = result;
    }
    if (unit != null) {
      $result.unit = unit;
    }
    if (formula != null) {
      $result.formula = formula;
    }
    return $result;
  }

  ConversionResponse._() : super();

  factory ConversionResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);

  factory ConversionResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
    _omitMessageNames ? '' : 'ConversionResponse',
    package: const $pb.PackageName(_omitMessageNames ? '' : 'tempconv'),
    createEmptyInstance: create,
  )
    ..a<$core.double>(1, _omitFieldNames ? '' : 'result', $pb.PbFieldType.OD)
    ..aOS(2, _omitFieldNames ? '' : 'unit')
    ..aOS(3, _omitFieldNames ? '' : 'formula')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConversionResponse clone() => ConversionResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConversionResponse copyWith(void Function(ConversionResponse) updates) =>
      super.copyWith((message) => updates(message as ConversionResponse))
          as ConversionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConversionResponse create() => ConversionResponse._();
  ConversionResponse createEmptyInstance() => create();

  @$core.pragma('dart2js:noInline')
  static ConversionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConversionResponse>(create);
  static ConversionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get result => $_getN(0);
  @$pb.TagNumber(1)
  set result($core.double v) {
    $_setDouble(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get unit => $_getSZ(1);
  @$pb.TagNumber(2)
  set unit($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUnit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnit() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get formula => $_getSZ(2);
  @$pb.TagNumber(3)
  set formula($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFormula() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormula() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
