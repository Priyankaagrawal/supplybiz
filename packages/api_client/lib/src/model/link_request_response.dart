//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'link_request_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkRequestResponse {
  /// Returns a new [LinkRequestResponse] instance.
  LinkRequestResponse({
    required this.id,
    required this.vendorId,
    required this.businessName,
  });

  /// The matching vendor-customer record ID.
  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'businessName',
    required: true,
    includeIfNull: true,
  )
  final String? businessName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkRequestResponse &&
          other.id == id &&
          other.vendorId == vendorId &&
          other.businessName == businessName;

  @override
  int get hashCode =>
      id.hashCode +
      vendorId.hashCode +
      (businessName == null ? 0 : businessName.hashCode);

  factory LinkRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$LinkRequestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LinkRequestResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
