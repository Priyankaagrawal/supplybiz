//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/vendor_assignment_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'current_plan_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CurrentPlanResponse {
  /// Returns a new [CurrentPlanResponse] instance.
  CurrentPlanResponse({
    required this.assignment,
    required this.status,
    required this.customerLimit,
    required this.activeCustomers,
    required this.canAddCustomer,
    required this.features,
  });

  @JsonKey(
    name: r'assignment',
    required: true,
    includeIfNull: true,
  )
  final VendorAssignmentResponse? assignment;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final CurrentPlanResponseStatusEnum status;

  @JsonKey(
    name: r'customerLimit',
    required: true,
    includeIfNull: false,
  )
  final int customerLimit;

  @JsonKey(
    name: r'activeCustomers',
    required: true,
    includeIfNull: false,
  )
  final int activeCustomers;

  @JsonKey(
    name: r'canAddCustomer',
    required: true,
    includeIfNull: false,
  )
  final bool canAddCustomer;

  @JsonKey(
    name: r'features',
    required: true,
    includeIfNull: false,
  )
  final List<String> features;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentPlanResponse &&
          other.assignment == assignment &&
          other.status == status &&
          other.customerLimit == customerLimit &&
          other.activeCustomers == activeCustomers &&
          other.canAddCustomer == canAddCustomer &&
          other.features == features;

  @override
  int get hashCode =>
      (assignment == null ? 0 : assignment.hashCode) +
      status.hashCode +
      customerLimit.hashCode +
      activeCustomers.hashCode +
      canAddCustomer.hashCode +
      features.hashCode;

  factory CurrentPlanResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrentPlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentPlanResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CurrentPlanResponseStatusEnum {
  @JsonValue(r'UNASSIGNED')
  UNASSIGNED(r'UNASSIGNED'),
  @JsonValue(r'SCHEDULED')
  SCHEDULED(r'SCHEDULED'),
  @JsonValue(r'ACTIVE')
  ACTIVE(r'ACTIVE'),
  @JsonValue(r'EXPIRED')
  EXPIRED(r'EXPIRED'),
  @JsonValue(r'UNAVAILABLE')
  UNAVAILABLE(r'UNAVAILABLE');

  const CurrentPlanResponseStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
