//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'payment_publication_ack.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentPublicationAck {
  /// Returns a new [PaymentPublicationAck] instance.
  PaymentPublicationAck({
    required this.version,
    required this.published,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'published',
    required: true,
    includeIfNull: false,
  )
  final bool published;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentPublicationAck &&
          other.version == version &&
          other.published == published;

  @override
  int get hashCode => version.hashCode + published.hashCode;

  factory PaymentPublicationAck.fromJson(Map<String, dynamic> json) =>
      _$PaymentPublicationAckFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentPublicationAckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
