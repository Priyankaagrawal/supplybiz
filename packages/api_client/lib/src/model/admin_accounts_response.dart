//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/admin_account_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_accounts_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminAccountsResponse {
  /// Returns a new [AdminAccountsResponse] instance.
  AdminAccountsResponse({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<AdminAccountResponse> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final num total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAccountsResponse &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory AdminAccountsResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminAccountsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminAccountsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
