//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'vendor_collection.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorCollection {
  /// Returns a new [VendorCollection] instance.
  VendorCollection({
    required this.id,
    required this.vendorCustomerId,
    required this.customerName,
    required this.amountPaise,
    required this.method,
    required this.entryDate,
    required this.createdAt,
    required this.reversal,
    required this.source_,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'customerName',
    required: true,
    includeIfNull: false,
  )
  final String customerName;

  /// Signed net receipt/correction, exact integer paise.
  @JsonKey(
    name: r'amountPaise',
    required: true,
    includeIfNull: false,
  )
  final String amountPaise;

  @JsonKey(
    name: r'method',
    required: true,
    includeIfNull: false,
  )
  final String method;

  @JsonKey(
    name: r'entryDate',
    required: true,
    includeIfNull: false,
  )
  final String entryDate;

  @JsonKey(
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )
  final String createdAt;

  @JsonKey(
    name: r'reversal',
    required: true,
    includeIfNull: false,
  )
  final bool reversal;

  @JsonKey(
    name: r'source',
    required: true,
    includeIfNull: false,
  )
  final String source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorCollection &&
          other.id == id &&
          other.vendorCustomerId == vendorCustomerId &&
          other.customerName == customerName &&
          other.amountPaise == amountPaise &&
          other.method == method &&
          other.entryDate == entryDate &&
          other.createdAt == createdAt &&
          other.reversal == reversal &&
          other.source_ == source_;

  @override
  int get hashCode =>
      id.hashCode +
      vendorCustomerId.hashCode +
      customerName.hashCode +
      amountPaise.hashCode +
      method.hashCode +
      entryDate.hashCode +
      createdAt.hashCode +
      reversal.hashCode +
      source_.hashCode;

  factory VendorCollection.fromJson(Map<String, dynamic> json) =>
      _$VendorCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$VendorCollectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
