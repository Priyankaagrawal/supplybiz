// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorDashboard _$VendorDashboardFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorDashboard',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'serverTime',
            'businessDate',
            'date',
            'shopName',
            'city',
            'shopPhotoMediaId',
            'verified',
            'todayOrders',
            'pendingOrders',
            'completedOrders',
            'todaySalesPaise',
            'totalEarningsPaise',
            'milkStockLitres',
            'milkStockUnmeasuredProducts',
            'activeCustomers'
          ],
        );
        final val = VendorDashboard(
          serverTime:
              $checkedConvert('serverTime', (v) => DateTime.parse(v as String)),
          businessDate: $checkedConvert(
              'businessDate', (v) => DateTime.parse(v as String)),
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          shopName: $checkedConvert('shopName', (v) => v as String?),
          city: $checkedConvert('city', (v) => v as String?),
          shopPhotoMediaId:
              $checkedConvert('shopPhotoMediaId', (v) => v as String?),
          verified: $checkedConvert('verified', (v) => v as bool),
          todayOrders:
              $checkedConvert('todayOrders', (v) => (v as num).toInt()),
          pendingOrders:
              $checkedConvert('pendingOrders', (v) => (v as num).toInt()),
          completedOrders:
              $checkedConvert('completedOrders', (v) => (v as num).toInt()),
          todaySalesPaise:
              $checkedConvert('todaySalesPaise', (v) => v as String),
          totalEarningsPaise:
              $checkedConvert('totalEarningsPaise', (v) => v as String),
          milkStockLitres:
              $checkedConvert('milkStockLitres', (v) => v as String),
          milkStockUnmeasuredProducts: $checkedConvert(
              'milkStockUnmeasuredProducts', (v) => (v as num).toInt()),
          activeCustomers:
              $checkedConvert('activeCustomers', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$VendorDashboardToJson(VendorDashboard instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime.toIso8601String(),
      'businessDate': instance.businessDate.toIso8601String(),
      'date': instance.date.toIso8601String(),
      'shopName': instance.shopName,
      'city': instance.city,
      'shopPhotoMediaId': instance.shopPhotoMediaId,
      'verified': instance.verified,
      'todayOrders': instance.todayOrders,
      'pendingOrders': instance.pendingOrders,
      'completedOrders': instance.completedOrders,
      'todaySalesPaise': instance.todaySalesPaise,
      'totalEarningsPaise': instance.totalEarningsPaise,
      'milkStockLitres': instance.milkStockLitres,
      'milkStockUnmeasuredProducts': instance.milkStockUnmeasuredProducts,
      'activeCustomers': instance.activeCustomers,
    };
