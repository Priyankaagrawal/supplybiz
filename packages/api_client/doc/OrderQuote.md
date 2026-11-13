# supplybiz_api_client.model.OrderQuote

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**serverTime** | **String** |  |
**businessDate** | [**DateTime**](DateTime.md) |  |
**sameDayCutoff** | **String** | Vendor-configured IST cutoff, HH:mm:ss; null disables today. |
**items** | [**List&lt;OrderPricedLine&gt;**](OrderPricedLine.md) |  |
**subtotalPaise** | **String** |  |
**deliveryChargePaise** | **String** |  |
**discountPaise** | **String** |  |
**totalPaise** | **String** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


