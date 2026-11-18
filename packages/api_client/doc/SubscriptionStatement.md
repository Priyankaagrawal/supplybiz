# supplybiz_api_client.model.SubscriptionStatement

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**subscriptionId** | **String** |  |
**month** | **String** |  |
**items** | [**List&lt;SubscriptionDelivery&gt;**](SubscriptionDelivery.md) |  |
**total** | **int** |  |
**deliveredAmountPaise** | **String** | Full selected-month delivered subtotal, independent of pagination. |
**deliveredQty** | **String** | Full selected-month delivered pack quantity, exact decimal string. |
**ledger** | [**KhataVendorEntries**](KhataVendorEntries.md) | Shared vendor account ledger. Unallocated payments/claims are not assigned to individual subscriptions. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


