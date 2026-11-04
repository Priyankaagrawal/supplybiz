//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/audit_snapshot.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit_row.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditRow {
  /// Returns a new [AuditRow] instance.
  AuditRow({
    required this.id,
    required this.actorType,
    required this.actorId,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.before,
    required this.after,
    required this.ip,
    required this.at,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'actor_type',
    required: true,
    includeIfNull: false,
  )
  final String actorType;

  @JsonKey(
    name: r'actor_id',
    required: true,
    includeIfNull: true,
  )
  final String? actorId;

  @JsonKey(
    name: r'action',
    required: true,
    includeIfNull: false,
  )
  final String action;

  @JsonKey(
    name: r'entity',
    required: true,
    includeIfNull: false,
  )
  final String entity;

  @JsonKey(
    name: r'entity_id',
    required: true,
    includeIfNull: true,
  )
  final String? entityId;

  @JsonKey(
    name: r'before',
    required: true,
    includeIfNull: true,
  )
  final AuditSnapshot? before;

  @JsonKey(
    name: r'after',
    required: true,
    includeIfNull: true,
  )
  final AuditSnapshot? after;

  @JsonKey(
    name: r'ip',
    required: true,
    includeIfNull: true,
  )
  final String? ip;

  @JsonKey(
    name: r'at',
    required: true,
    includeIfNull: false,
  )
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditRow &&
          other.id == id &&
          other.actorType == actorType &&
          other.actorId == actorId &&
          other.action == action &&
          other.entity == entity &&
          other.entityId == entityId &&
          other.before == before &&
          other.after == after &&
          other.ip == ip &&
          other.at == at;

  @override
  int get hashCode =>
      id.hashCode +
      actorType.hashCode +
      (actorId == null ? 0 : actorId.hashCode) +
      action.hashCode +
      entity.hashCode +
      (entityId == null ? 0 : entityId.hashCode) +
      (before == null ? 0 : before.hashCode) +
      (after == null ? 0 : after.hashCode) +
      (ip == null ? 0 : ip.hashCode) +
      at.hashCode;

  factory AuditRow.fromJson(Map<String, dynamic> json) =>
      _$AuditRowFromJson(json);

  Map<String, dynamic> toJson() => _$AuditRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
