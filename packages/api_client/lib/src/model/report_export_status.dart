//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'report_export_status.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportExportStatus {
  /// Returns a new [ReportExportStatus] instance.
  ReportExportStatus({
    required this.exportId,
    required this.status,
    required this.from,
    required this.to,
    required this.createdAt,
    required this.expiresAt,
    required this.format,
    required this.sizeBytes,
    required this.sha256,
    required this.downloadPath,
  });

  @JsonKey(
    name: r'exportId',
    required: true,
    includeIfNull: false,
  )
  final String exportId;

  /// Generated synchronously within operational limits. Download always rechecks live access.
  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final ReportExportStatusStatusEnum status;

  @JsonKey(
    name: r'from',
    required: true,
    includeIfNull: false,
  )
  final DateTime from;

  @JsonKey(
    name: r'to',
    required: true,
    includeIfNull: false,
  )
  final DateTime to;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime createdAt;

  @JsonKey(
    name: r'expiresAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime expiresAt;

  @JsonKey(
    name: r'format',
    required: true,
    includeIfNull: false,
  )
  final ReportExportStatusFormatEnum format;

  // minimum: 1
  // maximum: 8388608
  @JsonKey(
    name: r'sizeBytes',
    required: true,
    includeIfNull: false,
  )
  final int sizeBytes;

  @JsonKey(
    name: r'sha256',
    required: true,
    includeIfNull: false,
  )
  final String sha256;

  /// Same-API authenticated route only, never a filesystem path/public URL. Null after 24-hour artifact/retry window.
  @JsonKey(
    name: r'downloadPath',
    required: true,
    includeIfNull: true,
  )
  final String? downloadPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportExportStatus &&
          other.exportId == exportId &&
          other.status == status &&
          other.from == from &&
          other.to == to &&
          other.createdAt == createdAt &&
          other.expiresAt == expiresAt &&
          other.format == format &&
          other.sizeBytes == sizeBytes &&
          other.sha256 == sha256 &&
          other.downloadPath == downloadPath;

  @override
  int get hashCode =>
      exportId.hashCode +
      status.hashCode +
      from.hashCode +
      to.hashCode +
      createdAt.hashCode +
      expiresAt.hashCode +
      format.hashCode +
      sizeBytes.hashCode +
      sha256.hashCode +
      (downloadPath == null ? 0 : downloadPath.hashCode);

  factory ReportExportStatus.fromJson(Map<String, dynamic> json) =>
      _$ReportExportStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ReportExportStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Generated synchronously within operational limits. Download always rechecks live access.
enum ReportExportStatusStatusEnum {
  @JsonValue(r'READY')
  READY(r'READY'),
  @JsonValue(r'EXPIRED')
  EXPIRED(r'EXPIRED');

  const ReportExportStatusStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ReportExportStatusFormatEnum {
  @JsonValue(r'CSV')
  CSV(r'CSV');

  const ReportExportStatusFormatEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
