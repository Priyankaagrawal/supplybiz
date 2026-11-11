//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_customer.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedCustomer {
  /// Returns a new [ManagedCustomer] instance.
  ManagedCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.updatedAt,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: true,
  )
  final String? name;

  @JsonKey(
    name: r'mobile',
    required: true,
    includeIfNull: false,
  )
  final String mobile;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final ManagedCustomerStatusEnum status;

  @JsonKey(
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedCustomer &&
          other.id == id &&
          other.name == name &&
          other.mobile == mobile &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      id.hashCode +
      (name == null ? 0 : name.hashCode) +
      mobile.hashCode +
      status.hashCode +
      updatedAt.hashCode;

  factory ManagedCustomer.fromJson(Map<String, dynamic> json) =>
      _$ManagedCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedCustomerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedCustomerStatusEnum {
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'BLOCKED')
  BLOCKED(r'BLOCKED'),
  @JsonValue(r'DELETED')
  DELETED(r'DELETED');

  const ManagedCustomerStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
