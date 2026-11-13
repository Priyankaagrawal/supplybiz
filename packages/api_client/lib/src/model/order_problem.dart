//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/order_quote.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_problem.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrderProblem {
  /// Returns a new [OrderProblem] instance.
  OrderProblem({
    required this.type,
    required this.title,
    required this.status,
    required this.code,
    required this.detail,
    required this.requestId,
    this.quote,
    this.productId,
  });

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final String type;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final int status;

  @JsonKey(
    name: r'code',
    required: true,
    includeIfNull: false,
  )
  final String code;

  @JsonKey(
    name: r'detail',
    required: true,
    includeIfNull: false,
  )
  final String detail;

  @JsonKey(
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )
  final String requestId;

  @JsonKey(
    name: r'quote',
    required: false,
    includeIfNull: false,
  )
  final OrderQuote? quote;

  @JsonKey(
    name: r'productId',
    required: false,
    includeIfNull: false,
  )
  final String? productId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderProblem &&
          other.type == type &&
          other.title == title &&
          other.status == status &&
          other.code == code &&
          other.detail == detail &&
          other.requestId == requestId &&
          other.quote == quote &&
          other.productId == productId;

  @override
  int get hashCode =>
      type.hashCode +
      title.hashCode +
      status.hashCode +
      code.hashCode +
      detail.hashCode +
      requestId.hashCode +
      quote.hashCode +
      productId.hashCode;

  factory OrderProblem.fromJson(Map<String, dynamic> json) =>
      _$OrderProblemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
