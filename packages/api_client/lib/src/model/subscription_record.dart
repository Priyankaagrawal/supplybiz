//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:supplybiz_api_client/src/model/subscription_revision.dart';
import 'package:supplybiz_api_client/src/model/subscription_pause_record.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_record.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionRecord {
  /// Returns a new [SubscriptionRecord] instance.
  SubscriptionRecord({
    required this.id,
    required this.version,
    required this.status,
    required this.effectiveFrom,
    required this.vendorId,
    required this.vendorCustomerId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.weekdays,
    required this.timeSlot,
    required this.startDate,
    required this.endDate,
    required this.addressSnapshot,
    required this.paymentMethod,
    required this.createdBy,
    required this.dailyAmountPaise,
    required this.monthlyEstimatePaise,
    required this.estimateMonth,
    required this.revisions,
    required this.pauses,
    required this.skips,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final int version;

  @JsonKey(
    name: r'status',
    required: true,
    includeIfNull: false,
  )
  final String status;

  @JsonKey(
    name: r'effectiveFrom',
    required: true,
    includeIfNull: false,
  )
  final DateTime effectiveFrom;

  @JsonKey(
    name: r'vendorId',
    required: true,
    includeIfNull: false,
  )
  final String vendorId;

  @JsonKey(
    name: r'vendorCustomerId',
    required: true,
    includeIfNull: false,
  )
  final String vendorCustomerId;

  @JsonKey(
    name: r'productId',
    required: true,
    includeIfNull: false,
  )
  final String productId;

  @JsonKey(
    name: r'productName',
    required: true,
    includeIfNull: false,
  )
  final String productName;

  @JsonKey(
    name: r'qty',
    required: true,
    includeIfNull: false,
  )
  final int qty;

  @JsonKey(
    name: r'weekdays',
    required: true,
    includeIfNull: false,
  )
  final List<num> weekdays;

  @JsonKey(
    name: r'timeSlot',
    required: true,
    includeIfNull: false,
  )
  final String timeSlot;

  @JsonKey(
    name: r'startDate',
    required: true,
    includeIfNull: false,
  )
  final DateTime startDate;

  @JsonKey(
    name: r'endDate',
    required: true,
    includeIfNull: true,
  )
  final DateTime? endDate;

  @JsonKey(
    name: r'addressSnapshot',
    required: true,
    includeIfNull: false,
  )
  final Map<String, Object> addressSnapshot;

  @JsonKey(
    name: r'paymentMethod',
    required: true,
    includeIfNull: false,
  )
  final String paymentMethod;

  @JsonKey(
    name: r'createdBy',
    required: true,
    includeIfNull: false,
  )
  final String createdBy;

  @JsonKey(
    name: r'dailyAmountPaise',
    required: true,
    includeIfNull: false,
  )
  final String dailyAmountPaise;

  @JsonKey(
    name: r'monthlyEstimatePaise',
    required: true,
    includeIfNull: false,
  )
  final String monthlyEstimatePaise;

  /// Server IST month for the estimate; not an invoice.
  @JsonKey(
    name: r'estimateMonth',
    required: true,
    includeIfNull: false,
  )
  final String estimateMonth;

  @JsonKey(
    name: r'revisions',
    required: true,
    includeIfNull: false,
  )
  final List<SubscriptionRevision> revisions;

  @JsonKey(
    name: r'pauses',
    required: true,
    includeIfNull: false,
  )
  final List<SubscriptionPauseRecord> pauses;

  @JsonKey(
    name: r'skips',
    required: true,
    includeIfNull: false,
  )
  final List<String> skips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionRecord &&
          other.id == id &&
          other.version == version &&
          other.status == status &&
          other.effectiveFrom == effectiveFrom &&
          other.vendorId == vendorId &&
          other.vendorCustomerId == vendorCustomerId &&
          other.productId == productId &&
          other.productName == productName &&
          other.qty == qty &&
          other.weekdays == weekdays &&
          other.timeSlot == timeSlot &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.addressSnapshot == addressSnapshot &&
          other.paymentMethod == paymentMethod &&
          other.createdBy == createdBy &&
          other.dailyAmountPaise == dailyAmountPaise &&
          other.monthlyEstimatePaise == monthlyEstimatePaise &&
          other.estimateMonth == estimateMonth &&
          other.revisions == revisions &&
          other.pauses == pauses &&
          other.skips == skips;

  @override
  int get hashCode =>
      id.hashCode +
      version.hashCode +
      status.hashCode +
      effectiveFrom.hashCode +
      vendorId.hashCode +
      vendorCustomerId.hashCode +
      productId.hashCode +
      productName.hashCode +
      qty.hashCode +
      weekdays.hashCode +
      timeSlot.hashCode +
      startDate.hashCode +
      (endDate == null ? 0 : endDate.hashCode) +
      addressSnapshot.hashCode +
      paymentMethod.hashCode +
      createdBy.hashCode +
      dailyAmountPaise.hashCode +
      monthlyEstimatePaise.hashCode +
      estimateMonth.hashCode +
      revisions.hashCode +
      pauses.hashCode +
      skips.hashCode;

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionRecordFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionRecordToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
