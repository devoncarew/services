import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

// todo: code completion

@JsonSerializable()
class VersionResponse {
  final String dartVersion;
  final String flutterVersion;
  @JsonKey(includeIfNull: false)
  final List<String>? experiments;

  VersionResponse({
    required this.dartVersion,
    required this.flutterVersion,
    this.experiments,
  });

  factory VersionResponse.fromJson(Map<String, dynamic> json) =>
      _$VersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VersionResponseToJson(this);
}

@JsonSerializable()
class FormatRequest {
  final String source;
  @JsonKey(includeIfNull: false)
  final int? selectionOffset;

  FormatRequest(
    this.source, {
    this.selectionOffset,
  });

  factory FormatRequest.fromJson(Map<String, dynamic> json) =>
      _$FormatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FormatRequestToJson(this);
}

@JsonSerializable()
class FormatResponse {
  final String source;
  @JsonKey(includeIfNull: false)
  final int? selectionOffset;

  FormatResponse({
    required this.source,
    this.selectionOffset,
  });

  factory FormatResponse.fromJson(Map<String, dynamic> json) =>
      _$FormatResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FormatResponseToJson(this);
}

@JsonSerializable()
class AnalyzeRequest {
  final String source;

  AnalyzeRequest(this.source);

  factory AnalyzeRequest.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyzeRequestToJson(this);
}

@JsonSerializable()
class AnalyzeResponse {
  final List<AnalysisIssue> issues;

  AnalyzeResponse(this.issues);

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyzeResponseToJson(this);
}

@JsonSerializable()
class AnalysisIssue {
  final Severity severity;
  final String code;
  final String message;
  @JsonKey(includeIfNull: false)
  final String? correction;
  final Location start;
  final Location end;

  AnalysisIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.correction,
    required this.start,
    required this.end,
  });

  factory AnalysisIssue.fromJson(Map<String, dynamic> json) =>
      _$AnalysisIssueFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisIssueToJson(this);
}

@JsonSerializable()
class Location {
  int line;
  int column;

  Location(this.line, this.column);

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

enum Severity {
  none,
  info,
  warning,
  error,
}

@JsonSerializable()
class BuildRequest {
  final String source;

  BuildRequest(this.source);

  factory BuildRequest.fromJson(Map<String, dynamic> json) =>
      _$BuildRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BuildRequestToJson(this);
}

@JsonSerializable()
class BuildResponse {
  final String javaScript;

  BuildResponse({required this.javaScript});

  factory BuildResponse.fromJson(Map<String, dynamic> json) =>
      _$BuildResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BuildResponseToJson(this);
}

@JsonSerializable()
class ErrorResponse implements Exception {
  @JsonKey(name: 'error')
  final String message;

  ErrorResponse({required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  String toString() => 'ErrorResponse: $message';
}
