//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_publication_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentPublicationInput {
  /// Returns a new [PaymentPublicationInput] instance.
  PaymentPublicationInput({
    required this.version,
    required this.publish,
    this.upiId,
  });

  // minimum: 1
  // maximum: 2147483647
  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  /// Explicitly publish the supplied payment address only to linked customers, or unpublish. KYC data is never copied.
  @JsonKey(
    name: r'publish',
    required: true,
    includeIfNull: false,
  )
  final bool publish;

  @JsonKey(
    name: r'upiId',
    required: false,
    includeIfNull: false,
  )
  final String? upiId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentPublicationInput &&
          other.version == version &&
          other.publish == publish &&
          other.upiId == upiId;

  @override
  int get hashCode => version.hashCode + publish.hashCode + upiId.hashCode;

  factory PaymentPublicationInput.fromJson(Map<String, dynamic> json) =>
      _$PaymentPublicationInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentPublicationInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
