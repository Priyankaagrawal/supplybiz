//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'media_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MediaResponse {
  /// Returns a new [MediaResponse] instance.
  MediaResponse({
    required this.mediaId,
    required this.status,
  });

  @JsonKey(
    name: r'mediaId',
    required: true,
    includeIfNull: false,
  )
  final String mediaId;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final MediaResponseStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaResponse &&
          other.mediaId == mediaId &&
          other.status == status;

  @override
  int get hashCode => mediaId.hashCode + status.hashCode;

  factory MediaResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MediaResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MediaResponseStatusEnum {
  @JsonValue(r'READY')
  READY(r'READY');

  const MediaResponseStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
