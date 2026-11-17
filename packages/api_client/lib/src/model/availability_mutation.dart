//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/availability_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'availability_mutation.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AvailabilityMutation {
  /// Returns a new [AvailabilityMutation] instance.
  AvailabilityMutation({
    required this.cancelledOrders,
    required this.availability,
  });

  @JsonKey(
    name: r'cancelledOrders',
    required: true,
    includeIfNull: false,
  )
  final int cancelledOrders;

  @JsonKey(
    name: r'availability',
    required: true,
    includeIfNull: false,
  )
  final AvailabilityResponse availability;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityMutation &&
          other.cancelledOrders == cancelledOrders &&
          other.availability == availability;

  @override
  int get hashCode => cancelledOrders.hashCode + availability.hashCode;

  factory AvailabilityMutation.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityMutationFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityMutationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
