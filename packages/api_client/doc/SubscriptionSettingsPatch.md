# supplybiz_api_client.model.SubscriptionSettingsPatch

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**version** | **int** |  |
**autoAcceptSubscriptions** | **bool** | Enabling requires active BUSINESS+. | [optional]
**deliveryAvailable** | **bool** |  | [optional]
**deliveryStartTime** | **String** | IST daily delivery window. Both ends may be cleared with null; overnight windows are allowed. | [optional]
**deliveryEndTime** | **String** |  | [optional]
**maxDailyOrders** | **int** | Positive order limit; null is unlimited. Typed clients may use clearMaxDailyOrders. | [optional]
**dailyMilkCapacityLitres** | **String** | Positive exact litres, up to three fractional digits (1 ml), max 2147483.647. Null is unlimited. Typed clients may use clearDailyMilkCapacity. | [optional]
**pauseAllSubscriptions** | **bool** |  | [optional]
**clearDeliveryWindow** | **bool** | Set true to clear both delivery times. Cannot accompany non-null times. | [optional]
**clearMaxDailyOrders** | **bool** | Set true to remove the order limit. Cannot accompany a non-null limit. | [optional]
**clearDailyMilkCapacity** | **bool** | Set true to remove the milk limit. Cannot accompany a non-null limit. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


