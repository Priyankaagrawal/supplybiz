//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'deletion_preview.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionPreview {
  /// Returns a new [DeletionPreview] instance.
  DeletionPreview({
    required this.outstandingReceivablesPaise,
    required this.vendor,
  });

  /// Exact positive vendor receivables in paise; deletion does not settle dues.
  @JsonKey(
    name: r'outstandingReceivablesPaise',
    required: true,
    includeIfNull: false,
  )
  final String outstandingReceivablesPaise;

  @JsonKey(
    name: r'vendor',
    required: true,
    includeIfNull: false,
  )
  final bool vendor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionPreview &&
          other.outstandingReceivablesPaise == outstandingReceivablesPaise &&
          other.vendor == vendor;

  @override
  int get hashCode => outstandingReceivablesPaise.hashCode + vendor.hashCode;

  factory DeletionPreview.fromJson(Map<String, dynamic> json) =>
      _$DeletionPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
