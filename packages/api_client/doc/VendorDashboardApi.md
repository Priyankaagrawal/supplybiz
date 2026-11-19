# supplybiz_api_client.api.VendorDashboardApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorDashboardControllerGet**](VendorDashboardApi.md#vendordashboardcontrollerget) | **GET** /api/v1/vendor/dashboard |


# **vendorDashboardControllerGet**
> VendorDashboard vendorDashboardControllerGet(date)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorDashboardApi();
final String date = date_example; // String | IST calendar date; omitted uses database current IST date.

try {
    final response = api.vendorDashboardControllerGet(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorDashboardApi->vendorDashboardControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **String**| IST calendar date; omitted uses database current IST date. | [optional]

### Return type

[**VendorDashboard**](VendorDashboard.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

