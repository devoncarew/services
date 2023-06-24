// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionResponse _$VersionResponseFromJson(Map<String, dynamic> json) =>
    VersionResponse(
      dartVersion: json['dartVersion'] as String,
      flutterVersion: json['flutterVersion'] as String,
      experiments: (json['experiments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$VersionResponseToJson(VersionResponse instance) {
  final val = <String, dynamic>{
    'dartVersion': instance.dartVersion,
    'flutterVersion': instance.flutterVersion,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('experiments', instance.experiments);
  return val;
}

FormatRequest _$FormatRequestFromJson(Map<String, dynamic> json) =>
    FormatRequest(
      json['source'] as String,
      selectionOffset: json['selectionOffset'] as int?,
    );

Map<String, dynamic> _$FormatRequestToJson(FormatRequest instance) {
  final val = <String, dynamic>{
    'source': instance.source,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('selectionOffset', instance.selectionOffset);
  return val;
}

FormatResponse _$FormatResponseFromJson(Map<String, dynamic> json) =>
    FormatResponse(
      source: json['source'] as String,
      selectionOffset: json['selectionOffset'] as int?,
    );

Map<String, dynamic> _$FormatResponseToJson(FormatResponse instance) {
  final val = <String, dynamic>{
    'source': instance.source,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('selectionOffset', instance.selectionOffset);
  return val;
}

AnalyzeRequest _$AnalyzeRequestFromJson(Map<String, dynamic> json) =>
    AnalyzeRequest(
      json['source'] as String,
    );

Map<String, dynamic> _$AnalyzeRequestToJson(AnalyzeRequest instance) =>
    <String, dynamic>{
      'source': instance.source,
    };

AnalyzeResponse _$AnalyzeResponseFromJson(Map<String, dynamic> json) =>
    AnalyzeResponse(
      (json['issues'] as List<dynamic>)
          .map((e) => AnalysisIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalyzeResponseToJson(AnalyzeResponse instance) =>
    <String, dynamic>{
      'issues': instance.issues,
    };

AnalysisIssue _$AnalysisIssueFromJson(Map<String, dynamic> json) =>
    AnalysisIssue(
      severity: $enumDecode(_$SeverityEnumMap, json['severity']),
      code: json['code'] as String,
      message: json['message'] as String,
      correction: json['correction'] as String?,
      start: Location.fromJson(json['start'] as Map<String, dynamic>),
      end: Location.fromJson(json['end'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnalysisIssueToJson(AnalysisIssue instance) {
  final val = <String, dynamic>{
    'severity': _$SeverityEnumMap[instance.severity]!,
    'code': instance.code,
    'message': instance.message,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('correction', instance.correction);
  val['start'] = instance.start;
  val['end'] = instance.end;
  return val;
}

const _$SeverityEnumMap = {
  Severity.none: 'none',
  Severity.info: 'info',
  Severity.warning: 'warning',
  Severity.error: 'error',
};

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      json['line'] as int,
      json['column'] as int,
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'line': instance.line,
      'column': instance.column,
    };

BuildRequest _$BuildRequestFromJson(Map<String, dynamic> json) => BuildRequest(
      json['source'] as String,
    );

Map<String, dynamic> _$BuildRequestToJson(BuildRequest instance) =>
    <String, dynamic>{
      'source': instance.source,
    };

BuildResponse _$BuildResponseFromJson(Map<String, dynamic> json) =>
    BuildResponse(
      javaScript: json['javaScript'] as String,
    );

Map<String, dynamic> _$BuildResponseToJson(BuildResponse instance) =>
    <String, dynamic>{
      'javaScript': instance.javaScript,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      message: json['error'] as String,
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.message,
    };
