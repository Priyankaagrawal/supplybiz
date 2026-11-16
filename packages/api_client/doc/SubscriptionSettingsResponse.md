# supplybiz_api_client.model.SubscriptionSettingsResponse

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**version** | **int** |  |
**serverTime** | **String** |  |
**businessDate** | [**DateTime**](DateTime.md) |  |
**autoAcceptSubscriptions** | **bool** |  |
**effectiveAutoAcceptSubscriptions** | **bool** |  |
**canAutoAccept** | **bool** |  |
**canEditSubscriptions** | **bool** |  |
**canReduceActivity** | **bool** | Owned reducing controls remain available with history access after expiry/downgrade. |
**deliveryAvailable** | **bool** |  |
**deliveryStartTime** | **String** |  |
**deliveryEndTime** | **String** |  |
**maxDailyOrders** | **int** |  |
**dailyMilkCapacityLitres** | **String** |  |
**pauseAllSubscriptions** | **bool** |  |
**summary** | [**SubscriptionSettingsSummary**](SubscriptionSettingsSummary.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


