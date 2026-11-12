//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/address_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'address_list.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressList {
  /// Returns a new [AddressList] instance.
  AddressList({
    required this.items,
  });

  @JsonKey(
    name: r'items',
    required: true,
    includeIfNull: false,
  )
  final List<AddressResponse> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AddressList && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory AddressList.fromJson(Map<String, dynamic> json) =>
      _$AddressListFromJson(json);

  Map<String, dynamic> toJson() => _$AddressListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
