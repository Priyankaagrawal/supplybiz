# supplybiz_api_client.api.AdminDashboardApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**dashboardControllerGet**](AdminDashboardApi.md#dashboardcontrollerget) | **GET** /api/v1/admin/dashboard |


# **dashboardControllerGet**
> AdminDashboard dashboardControllerGet()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminDashboardApi();

try {
    final response = api.dashboardControllerGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminDashboardApi->dashboardControllerGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminDashboard**](AdminDashboard.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

