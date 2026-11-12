# supplybiz_api_client.api.CustomerHomeApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**homeControllerGet**](CustomerHomeApi.md#homecontrollerget) | **GET** /api/v1/customer/home |


# **homeControllerGet**
> CustomerHome homeControllerGet(lat, lng, pincode, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerHomeApi();
final num lat = 8.14; // num | Optional location pair; does not filter owned deliveries.
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final num limit = 8.14; // num |
final String cursor = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Last order ID from this customer and current IST day.

try {
    final response = api.homeControllerGet(lat, lng, pincode, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerHomeApi->homeControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**| Optional location pair; does not filter owned deliveries. | [optional]
 **lng** | **num**|  | [optional]
 **pincode** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**| Last order ID from this customer and current IST day. | [optional]

### Return type

[**CustomerHome**](CustomerHome.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

