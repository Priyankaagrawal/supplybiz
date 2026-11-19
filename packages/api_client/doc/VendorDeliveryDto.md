# supplybiz_api_client.model.VendorDeliveryDto

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**version** | **int** |  |
**deliveryChargePaise** | **int** |  |
**minOrderPaise** | **int** |  |
**timeSlots** | **List&lt;String&gt;** | Explicit IST HH:mm-HH:mm slots; no overnight/overlapping slots. Empty disables checkout slots. |
**acceptingToday** | **bool** |  |
**sameDayCutoff** | **String** | IST HH:mm; required when acceptingToday is true. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


