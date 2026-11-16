# supplybiz_api_client.model.SubscriptionRecord

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**version** | **int** |  |
**status** | **String** |  |
**effectiveFrom** | [**DateTime**](DateTime.md) |  |
**vendorId** | **String** |  |
**vendorCustomerId** | **String** |  |
**productId** | **String** |  |
**productName** | **String** |  |
**qty** | **int** |  |
**weekdays** | **List&lt;num&gt;** |  |
**timeSlot** | **String** |  |
**startDate** | [**DateTime**](DateTime.md) |  |
**endDate** | [**DateTime**](DateTime.md) |  |
**addressSnapshot** | **Map&lt;String, Object&gt;** |  |
**paymentMethod** | **String** |  |
**createdBy** | **String** |  |
**dailyAmountPaise** | **String** |  |
**monthlyEstimatePaise** | **String** |  |
**estimateMonth** | **String** | Server IST month for the estimate; not an invoice. |
**revisions** | [**List&lt;SubscriptionRevision&gt;**](SubscriptionRevision.md) |  |
**pauses** | [**List&lt;SubscriptionPauseRecord&gt;**](SubscriptionPauseRecord.md) |  |
**skips** | **List&lt;String&gt;** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


