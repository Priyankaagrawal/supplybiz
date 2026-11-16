# supplybiz_api_client.model.CustomerSubscriptionInput

## Load the model package
```dart
import 'package:supplybiz_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**productId** | **String** |  |
**qty** | **int** |  |
**weekdays** | **List&lt;num&gt;** | ISO weekdays 1=Monday through 7=Sunday, unique. |
**startDate** | [**DateTime**](DateTime.md) |  |
**endDate** | [**DateTime**](DateTime.md) |  | [optional]
**timeSlot** | **String** |  |
**paymentMethod** | **String** | External payment preference; postpaid Khata, no funds held or prepaid charge. |
**vendorId** | **String** |  |
**addressId** | **String** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


