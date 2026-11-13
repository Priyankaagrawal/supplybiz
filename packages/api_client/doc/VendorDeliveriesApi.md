# supplybiz_api_client.api.VendorDeliveriesApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorDeliveriesControllerList**](VendorDeliveriesApi.md#vendordeliveriescontrollerlist) | **GET** /api/v1/vendor/deliveries |


# **vendorDeliveriesControllerList**
> DeliveryList vendorDeliveriesControllerList(date, limit, offset, status)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorDeliveriesApi();
final DateTime date = 2013-10-20; // DateTime |
final int limit = 56; // int |
final int offset = 56; // int |
final String status = status_example; // String |

try {
    final response = api.vendorDeliveriesControllerList(date, limit, offset, status);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorDeliveriesApi->vendorDeliveriesControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **status** | **String**|  | [optional]

### Return type

[**DeliveryList**](DeliveryList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

