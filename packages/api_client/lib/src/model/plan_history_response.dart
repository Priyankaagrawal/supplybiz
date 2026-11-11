//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/plan_history_row.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_history_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanHistoryResponse {
  /// Returns a new [PlanHistoryResponse] instance.
  PlanHistoryResponse({
    required this.items,
    required this.total,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<PlanHistoryRow> items;

  @JsonKey(
    name: r'total',
    required: true,
    includeIfNull: false,
  )
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanHistoryResponse &&
          other.items == items &&
          other.total == total;

  @override
  int get hashCode => items.hashCode + total.hashCode;

  factory PlanHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanHistoryResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
